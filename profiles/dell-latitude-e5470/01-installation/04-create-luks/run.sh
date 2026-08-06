#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly EXPECTED_PARTITION_TYPE="CA7D7CCB-63ED-4C53-861C-1742536059CC"
readonly MAPPER_NAME="cryptroot"
readonly MAPPER_PATH="/dev/mapper/${MAPPER_NAME}"

TARGET_PARTITION=""

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
  sudo ./$SCRIPT_NAME --partition /dev/<partition>

Examples:
  sudo ./$SCRIPT_NAME --partition /dev/sda2
  sudo ./$SCRIPT_NAME --partition /dev/nvme0n1p2

This operation:

  1. Permanently erases the selected partition.
  2. Creates a LUKS2 container.
  3. Opens it as ${MAPPER_PATH}.

The passphrase is requested interactively by cryptsetup.
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
    lsblk
    readlink
    udevadm
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
      --partition)
        (($# >= 2)) ||
          die "Missing value for --partition."

        TARGET_PARTITION="$2"
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

  [[ -n "$TARGET_PARTITION" ]] ||
    die "The --partition argument is required."
}

canonicalize_partition() {
  TARGET_PARTITION="$(readlink -f "$TARGET_PARTITION")"

  [[ -b "$TARGET_PARTITION" ]] ||
    die "Target is not a block device: $TARGET_PARTITION"

  [[ "$(lsblk -dnro TYPE "$TARGET_PARTITION")" == "part" ]] ||
    die "Target must be a partition: $TARGET_PARTITION"

  [[ "$(blockdev --getro "$TARGET_PARTITION")" == "0" ]] ||
    die "Target partition is read-only: $TARGET_PARTITION"
}

validate_partition_type() {
  local actual_type

  actual_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output PARTTYPE \
      "$TARGET_PARTITION" |
      xargs |
      tr '[:lower:]' '[:upper:]'
  )"

  [[ "$actual_type" == "$EXPECTED_PARTITION_TYPE" ]] ||
    die "Partition is not marked as Linux LUKS: $TARGET_PARTITION"
}

validate_not_mounted() {
  local mountpoints

  mountpoints="$(
    lsblk \
      --noheadings \
      --output MOUNTPOINTS \
      "$TARGET_PARTITION" |
      sed '/^[[:space:]]*$/d'
  )"

  [[ -z "$mountpoints" ]] ||
    die "Target partition is mounted and cannot be formatted."
}

validate_no_active_holders() {
  local holder_count

  holder_count="$(
    ls "/sys/class/block/$(basename "$TARGET_PARTITION")/holders" \
      2>/dev/null |
      wc -l
  )"

  ((holder_count == 0)) ||
    die "Target partition has active device-mapper holders."
}

validate_mapper_available() {
  if [[ -e "$MAPPER_PATH" ]]; then
    die "Mapper already exists: $MAPPER_PATH"
  fi

  if cryptsetup status "$MAPPER_NAME" >/dev/null 2>&1; then
    die "Mapper name is already active: $MAPPER_NAME"
  fi
}

validate_not_already_luks() {
  if cryptsetup isLuks "$TARGET_PARTITION" >/dev/null 2>&1; then
    die "Target partition already contains a LUKS header."
  fi
}

show_target_summary() {
  local parent
  local size
  local model
  local serial

  parent="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output PKNAME \
      "$TARGET_PARTITION" |
      xargs
  )"

  size="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output SIZE \
      "$TARGET_PARTITION" |
      xargs
  )"

  model="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output MODEL \
      "/dev/${parent}" |
      xargs
  )"

  serial="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output SERIAL \
      "/dev/${parent}" |
      xargs
  )"

  cat <<EOF

Target partition
----------------

Partition: $TARGET_PARTITION
Parent:    /dev/${parent}
Size:      ${size:-unknown}
Model:     ${model:-unknown}
Serial:    ${serial:-unknown}

Encryption
----------

Format: LUKS2
Mapper: ${MAPPER_PATH}

WARNING: ALL DATA ON $TARGET_PARTITION WILL BE PERMANENTLY ERASED.
EOF
}

confirm_destruction() {
  local confirmed_partition
  local confirmation

  printf '\nType the complete target partition path to confirm: '
  read -r confirmed_partition

  [[ "$confirmed_partition" == "$TARGET_PARTITION" ]] ||
    die "Target partition confirmation did not match."

  printf 'Type ERASE to authorize permanent data destruction: '
  read -r confirmation

  [[ "$confirmation" == "ERASE" ]] ||
    die "Destructive operation was not authorized."
}

create_luks_container() {
  log "Creating LUKS2 container."

  printf '\n'
  warn "You will now be prompted to create the LUKS passphrase."
  warn "The passphrase will not be stored by this script."
  printf '\n'

  cryptsetup \
    --type luks2 \
    --verify-passphrase \
    luksFormat \
    "$TARGET_PARTITION"
}

validate_luks_container() {
  local luks_version

  cryptsetup isLuks "$TARGET_PARTITION" ||
    die "The target partition does not contain a valid LUKS header."

  luks_version="$(
    cryptsetup luksDump "$TARGET_PARTITION" |
      awk -F: '
        /^Version:/ {
          gsub(/[[:space:]]/, "", $2)
          print $2
          exit
        }
      '
  )"

  [[ "$luks_version" == "2" ]] ||
    die "Expected LUKS version 2, found: ${luks_version:-unknown}"
}

open_luks_container() {
  log "Opening LUKS2 container as ${MAPPER_NAME}."

  printf '\n'
  warn "Enter the LUKS passphrase to open the container."
  printf '\n'

  cryptsetup open \
    --type luks2 \
    "$TARGET_PARTITION" \
    "$MAPPER_NAME"

  udevadm settle
}

validate_mapping() {
  [[ -b "$MAPPER_PATH" ]] ||
    die "Mapped device was not created: $MAPPER_PATH"

  cryptsetup status "$MAPPER_NAME" >/dev/null ||
    die "Mapped device is not reported as active."

  local backing_device

  backing_device="$(
    cryptsetup status "$MAPPER_NAME" |
      awk -F: '
        /^[[:space:]]*device:/ {
          sub(/^[[:space:]]+/, "", $2)
          print $2
          exit
        }
      '
  )"

  backing_device="$(readlink -f "$backing_device")"

  [[ "$backing_device" == "$TARGET_PARTITION" ]] ||
    die "Mapper does not reference the expected target partition."
}

show_result() {
  printf '\nLUKS2 container created and opened successfully.\n\n'

  cryptsetup status "$MAPPER_NAME"

  printf '\nBlock device layout:\n\n'

  lsblk \
    --output NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS \
    "$TARGET_PARTITION"

  printf '\nNext step:\n'
  printf '  05-create-btrfs\n'
  printf '\nMapped device:\n'
  printf '  %s\n' "$MAPPER_PATH"
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_partition
  validate_partition_type
  validate_not_mounted
  validate_no_active_holders
  validate_mapper_available
  validate_not_already_luks
  show_target_summary
  confirm_destruction
  create_luks_container
  validate_luks_container
  open_luks_container
  validate_mapping
  show_result
}

main "$@"
