```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_DEVICE="/dev/mapper/cryptroot"
readonly DEFAULT_LABEL="linux-workstation"

TARGET_DEVICE="$DEFAULT_DEVICE"
FILESYSTEM_LABEL="$DEFAULT_LABEL"

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  local line_number=$1

  printf '[ERROR] %s failed at line %s with exit code %s.\n' \
    "$SCRIPT_NAME" \
    "$line_number" \
    "$exit_code" >&2

  exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [options]

Options:
  --device <path>   Target mapped device.
                    Default: ${DEFAULT_DEVICE}

  --label <label>   Btrfs filesystem label.
                    Default: ${DEFAULT_LABEL}

  --help, -h        Show this help message.

Examples:
  sudo ./$SCRIPT_NAME

  sudo ./$SCRIPT_NAME \\
    --device /dev/mapper/cryptroot \\
    --label linux-workstation

This operation creates a new Btrfs filesystem and permanently erases
any existing filesystem data on the selected mapped device.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    blockdev
    cryptsetup
    findmnt
    lsblk
    mkfs.btrfs
    readlink
    udevadm
    wipefs
  )

  local command_name

  for command_name in "${commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      die "Required command not found: $command_name"
  done
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --device)
        (($# >= 2)) ||
          die "Missing value for --device."

        TARGET_DEVICE="$2"
        shift 2
        ;;

      --label)
        (($# >= 2)) ||
          die "Missing value for --label."

        FILESYSTEM_LABEL="$2"
        shift 2
        ;;

      --help | -h)
        usage
        exit 0
        ;;

      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

canonicalize_device() {
  TARGET_DEVICE="$(readlink -f "$TARGET_DEVICE")"

  [[ -b "$TARGET_DEVICE" ]] ||
    die "Target is not a block device: $TARGET_DEVICE"

  [[ "$(blockdev --getro "$TARGET_DEVICE")" == "0" ]] ||
    die "Target device is read-only: $TARGET_DEVICE"
}

validate_label() {
  [[ -n "$FILESYSTEM_LABEL" ]] ||
    die "Filesystem label cannot be empty."

  ((${#FILESYSTEM_LABEL} <= 256)) ||
    die "Filesystem label exceeds the Btrfs label limit."

  [[ "$FILESYSTEM_LABEL" != *$'\n'* ]] ||
    die "Filesystem label cannot contain line breaks."
}

validate_device_type() {
  local device_type

  device_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output TYPE \
      "$TARGET_DEVICE" |
      xargs
  )"

  [[ "$device_type" == "crypt" ]] ||
    die "Target must be an active encrypted mapping: $TARGET_DEVICE"
}

validate_expected_mapper() {
  local mapper_name

  mapper_name="$(basename "$TARGET_DEVICE")"

  cryptsetup status "$mapper_name" >/dev/null 2>&1 ||
    die "Target is not an active cryptsetup mapping: $TARGET_DEVICE"
}

validate_not_mounted() {
  if findmnt --noheadings --source "$TARGET_DEVICE" >/dev/null 2>&1; then
    die "Target device is mounted and cannot be formatted."
  fi

  local mountpoints

  mountpoints="$(
    lsblk \
      --noheadings \
      --output MOUNTPOINTS \
      "$TARGET_DEVICE" |
      sed '/^[[:space:]]*$/d'
  )"

  [[ -z "$mountpoints" ]] ||
    die "Target device or one of its descendants is mounted."
}

validate_no_children() {
  local child_count

  child_count="$(
    lsblk \
      --noheadings \
      --output TYPE \
      "$TARGET_DEVICE" |
      awk 'NR > 1 { count++ } END { print count + 0 }'
  )"

  ((child_count == 0)) ||
    die "Target device has unexpected child devices."
}

validate_minimum_size() {
  local size_bytes
  local minimum_size_bytes=$((4 * 1024 * 1024 * 1024))

  size_bytes="$(blockdev --getsize64 "$TARGET_DEVICE")"

  ((size_bytes >= minimum_size_bytes)) ||
    die "Target device must have at least 4 GiB."
}

detect_existing_signatures() {
  wipefs --noheadings "$TARGET_DEVICE" 2>/dev/null || true
}

show_target_summary() {
  local mapper_name
  local backing_device
  local size
  local existing_signatures

  mapper_name="$(basename "$TARGET_DEVICE")"

  backing_device="$(
    cryptsetup status "$mapper_name" |
      awk -F: '
        /^[[:space:]]*device:/ {
          sub(/^[[:space:]]+/, "", $2)
          print $2
          exit
        }
      '
  )"

  backing_device="$(readlink -f "$backing_device")"

  size="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output SIZE \
      "$TARGET_DEVICE" |
      xargs
  )"

  existing_signatures="$(detect_existing_signatures)"

  cat <<EOF

Target device
-------------

Mapped device:  $TARGET_DEVICE
Backing device: ${backing_device:-unknown}
Size:           ${size:-unknown}

Filesystem
----------

Type:  Btrfs
Label: $FILESYSTEM_LABEL

WARNING: ALL FILESYSTEM DATA ON $TARGET_DEVICE WILL BE PERMANENTLY ERASED.
EOF

  if [[ -n "$existing_signatures" ]]; then
    printf '\nExisting signatures detected:\n\n'
    printf '%s\n' "$existing_signatures"
  else
    printf '\nNo existing filesystem signatures were detected.\n'
  fi
}

confirm_destruction() {
  local confirmed_device
  local confirmation

  printf '\nType the complete mapped device path to confirm: '
  read -r confirmed_device

  [[ "$confirmed_device" == "$TARGET_DEVICE" ]] ||
    die "Target device confirmation did not match."

  printf 'Type ERASE to authorize filesystem creation: '
  read -r confirmation

  [[ "$confirmation" == "ERASE" ]] ||
    die "Destructive operation was not authorized."
}

create_filesystem() {
  log "Creating Btrfs filesystem on $TARGET_DEVICE."

  mkfs.btrfs \
    --force \
    --label "$FILESYSTEM_LABEL" \
    "$TARGET_DEVICE"

  udevadm settle
}

validate_filesystem() {
  local filesystem_type
  local filesystem_label
  local filesystem_uuid

  filesystem_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output FSTYPE \
      "$TARGET_DEVICE" |
      xargs
  )"

  filesystem_label="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output LABEL \
      "$TARGET_DEVICE" |
      xargs
  )"

  filesystem_uuid="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output UUID \
      "$TARGET_DEVICE" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs filesystem, found: ${filesystem_type:-unknown}"

  [[ "$filesystem_label" == "$FILESYSTEM_LABEL" ]] ||
    die "Filesystem label does not match the expected value."

  [[ -n "$filesystem_uuid" ]] ||
    die "Filesystem UUID was not generated."
}

show_result() {
  printf '\nBtrfs filesystem created successfully.\n\n'

  lsblk \
    --output NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS \
    "$TARGET_DEVICE"

  printf '\nNext step:\n'
  printf '  06-create-subvolumes\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_device
  validate_label
  validate_device_type
  validate_expected_mapper
  validate_not_mounted
  validate_no_children
  validate_minimum_size
  show_target_summary
  confirm_destruction
  create_filesystem
  validate_filesystem
  show_result
}

main "$@"
```
