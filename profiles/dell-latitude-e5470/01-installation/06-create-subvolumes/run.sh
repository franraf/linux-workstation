#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_DEVICE="/dev/mapper/cryptroot"
readonly DEFAULT_MOUNTPOINT="/mnt/btrfs-root"

readonly SUBVOLUMES=(
  "@"
  "@home"
  "@var"
  "@var_log"
  "@var_cache"
  "@pkg"
  "@docker"
  "@snapshots"
)

TARGET_DEVICE="$DEFAULT_DEVICE"
TEMP_MOUNTPOINT="$DEFAULT_MOUNTPOINT"
MOUNTED_BY_SCRIPT=false

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

cleanup() {
  local exit_code=$?

  trap - EXIT ERR INT TERM

  if [[ "$MOUNTED_BY_SCRIPT" == true ]] &&
    mountpoint --quiet "$TEMP_MOUNTPOINT"; then
    log "Unmounting temporary Btrfs mount."

    if ! umount "$TEMP_MOUNTPOINT"; then
      warn "Unable to unmount temporary mountpoint: $TEMP_MOUNTPOINT"
      exit 1
    fi
  fi

  if [[ -d "$TEMP_MOUNTPOINT" ]]; then
    rmdir "$TEMP_MOUNTPOINT" 2>/dev/null || true
  fi

  exit "$exit_code"
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
trap cleanup EXIT INT TERM

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [options]

Options:
  --device <path>       Btrfs block device.
                        Default: ${DEFAULT_DEVICE}

  --mountpoint <path>   Temporary mountpoint.
                        Default: ${DEFAULT_MOUNTPOINT}

  --help, -h            Show this help message.

Examples:
  sudo ./$SCRIPT_NAME

  sudo ./$SCRIPT_NAME \\
    --device /dev/mapper/cryptroot \\
    --mountpoint /mnt/btrfs-root

This script creates the following Btrfs subvolumes:

$(printf '  - %s\n' "${SUBVOLUMES[@]}")
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    btrfs
    findmnt
    lsblk
    mkdir
    mount
    mountpoint
    readlink
    rmdir
    umount
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

      --mountpoint)
        (($# >= 2)) ||
          die "Missing value for --mountpoint."

        TEMP_MOUNTPOINT="$2"
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
}

validate_mountpoint() {
  [[ "$TEMP_MOUNTPOINT" == /* ]] ||
    die "Temporary mountpoint must be an absolute path."

  [[ "$TEMP_MOUNTPOINT" != "/" ]] ||
    die "Refusing to use / as the temporary mountpoint."

  [[ "$TEMP_MOUNTPOINT" != "/mnt" ]] ||
    die "Refusing to use /mnt directly as the temporary mountpoint."

  if mountpoint --quiet "$TEMP_MOUNTPOINT"; then
    die "Temporary mountpoint is already in use: $TEMP_MOUNTPOINT"
  fi

  if [[ -e "$TEMP_MOUNTPOINT" && ! -d "$TEMP_MOUNTPOINT" ]]; then
    die "Temporary mountpoint exists and is not a directory."
  fi

  if [[ -d "$TEMP_MOUNTPOINT" ]] &&
    [[ -n "$(find "$TEMP_MOUNTPOINT" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    die "Temporary mountpoint is not empty: $TEMP_MOUNTPOINT"
  fi
}

validate_filesystem() {
  local filesystem_type

  filesystem_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output FSTYPE \
      "$TARGET_DEVICE" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Target device does not contain a Btrfs filesystem."
}

validate_not_mounted_elsewhere() {
  local active_mounts

  active_mounts="$(
    findmnt \
      --noheadings \
      --raw \
      --source "$TARGET_DEVICE" \
      --output TARGET 2>/dev/null || true
  )"

  [[ -z "$active_mounts" ]] ||
    die "Target device is already mounted at: $active_mounts"
}

prepare_mountpoint() {
  mkdir -p "$TEMP_MOUNTPOINT"
}

mount_top_level() {
  log "Mounting the Btrfs top-level subvolume."

  mount \
    --types btrfs \
    --options subvolid=5 \
    "$TARGET_DEVICE" \
    "$TEMP_MOUNTPOINT"

  MOUNTED_BY_SCRIPT=true

  mountpoint --quiet "$TEMP_MOUNTPOINT" ||
    die "Temporary mountpoint was not mounted successfully."
}

list_existing_subvolumes() {
  btrfs subvolume list \
    --only-in-path \
    "$TEMP_MOUNTPOINT" 2>/dev/null |
    awk '{print $NF}' |
    sort
}

validate_initial_state() {
  local existing_subvolumes

  existing_subvolumes="$(list_existing_subvolumes)"

  if [[ -n "$existing_subvolumes" ]]; then
    printf '\nExisting subvolumes were detected:\n\n'
    printf '%s\n' "$existing_subvolumes"
    printf '\n'

    die "Refusing to modify a Btrfs filesystem that already has subvolumes."
  fi
}

show_plan() {
  cat <<EOF

Target filesystem
-----------------

Device:              $TARGET_DEVICE
Temporary mountpoint: $TEMP_MOUNTPOINT

Subvolumes to create
--------------------

$(printf '  - %s\n' "${SUBVOLUMES[@]}")

No existing subvolumes were detected.
EOF
}

confirm_creation() {
  local confirmation

  printf '\nType CREATE to create the subvolume structure: '
  read -r confirmation

  [[ "$confirmation" == "CREATE" ]] ||
    die "Subvolume creation was not authorized."
}

create_subvolumes() {
  local subvolume

  for subvolume in "${SUBVOLUMES[@]}"; do
    log "Creating subvolume: $subvolume"

    btrfs subvolume create \
      "$TEMP_MOUNTPOINT/$subvolume"
  done
}

validate_subvolume() {
  local subvolume=$1
  local subvolume_path="$TEMP_MOUNTPOINT/$subvolume"

  [[ -d "$subvolume_path" ]] ||
    die "Subvolume directory does not exist: $subvolume"

  btrfs subvolume show "$subvolume_path" >/dev/null ||
    die "Path is not a valid Btrfs subvolume: $subvolume"
}

validate_subvolumes() {
  local subvolume
  local actual_count
  local expected_count="${#SUBVOLUMES[@]}"

  for subvolume in "${SUBVOLUMES[@]}"; do
    validate_subvolume "$subvolume"
  done

  actual_count="$(
    btrfs subvolume list \
      --only-in-path \
      "$TEMP_MOUNTPOINT" |
      wc -l
  )"

  ((actual_count == expected_count)) ||
    die "Expected $expected_count subvolumes, found $actual_count."
}

show_result() {
  printf '\nBtrfs subvolumes created successfully.\n\n'

  btrfs subvolume list \
    --sort=path \
    "$TEMP_MOUNTPOINT"

  printf '\nNext step:\n'
  printf '  07-mount-filesystems\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_device
  validate_mountpoint
  validate_filesystem
  validate_not_mounted_elsewhere
  prepare_mountpoint
  mount_top_level
  validate_initial_state
  show_plan
  confirm_creation
  create_subvolumes
  validate_subvolumes
  show_result
}

main "$@"
