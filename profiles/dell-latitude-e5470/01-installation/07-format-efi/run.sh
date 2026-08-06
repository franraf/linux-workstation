#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly EXPECTED_PARTITION_TYPE="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
readonly DEFAULT_LABEL="EFI"

TARGET_PARTITION=""
FILESYSTEM_LABEL="$DEFAULT_LABEL"

log() {
  printf '[INFO] %s\n' "$*"
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
  sudo ./$SCRIPT_NAME --partition /dev/<partition> [options]

Options:
  --partition <path>  EFI System Partition to format.
  --label <label>     FAT32 filesystem label.
                      Default: ${DEFAULT_LABEL}
  --help, -h          Show this help message.

Examples:
  sudo ./$SCRIPT_NAME --partition /dev/sda1

  sudo ./$SCRIPT_NAME \
    --partition /dev/nvme0n1p1 \
    --label EFI

This operation permanently erases the selected partition and creates
a FAT32 filesystem suitable for use as an EFI System Partition.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_uefi() {
  [[ -d /sys/firmware/efi ]] ||
    die "The installation environment was not booted in UEFI mode."
}

require_commands() {
  local commands=(
    blockdev
    findmnt
    lsblk
    mkfs.fat
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
      --partition)
        (($# >= 2)) || die "Missing value for --partition."
        TARGET_PARTITION="$2"
        shift 2
        ;;

      --label)
        (($# >= 2)) || die "Missing value for --label."
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
    die "Partition is not marked as an EFI System Partition."
}

validate_partition_size() {
  local size_bytes
  local minimum_size_bytes=$((260 * 1024 * 1024))

  size_bytes="$(blockdev --getsize64 "$TARGET_PARTITION")"

  ((size_bytes >= minimum_size_bytes)) ||
    die "EFI System Partition must have at least 260 MiB."
}

validate_not_mounted() {
  if findmnt --noheadings --source "$TARGET_PARTITION" \
    >/dev/null 2>&1; then
    die "Target partition is mounted and cannot be formatted."
  fi

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

validate_label() {
  [[ -n "$FILESYSTEM_LABEL" ]] ||
    die "Filesystem label cannot be empty."

  ((${#FILESYSTEM_LABEL} <= 11)) ||
    die "FAT filesystem label cannot exceed 11 characters."

  [[ "$FILESYSTEM_LABEL" =~ ^[A-Za-z0-9_-]+$ ]] ||
    die "Filesystem label contains unsupported characters."
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

Filesystem
----------

Type:  FAT32
Label: $FILESYSTEM_LABEL

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

  printf 'Type ERASE to authorize filesystem creation: '
  read -r confirmation

  [[ "$confirmation" == "ERASE" ]] ||
    die "Destructive operation was not authorized."
}

create_filesystem() {
  log "Removing existing filesystem signatures."

  wipefs --all --force "$TARGET_PARTITION"

  log "Creating FAT32 filesystem."

  mkfs.fat \
    -F 32 \
    -n "$FILESYSTEM_LABEL" \
    "$TARGET_PARTITION"

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
      "$TARGET_PARTITION" |
      xargs
  )"

  filesystem_label="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output LABEL \
      "$TARGET_PARTITION" |
      xargs
  )"

  filesystem_uuid="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output UUID \
      "$TARGET_PARTITION" |
      xargs
  )"

  [[ "$filesystem_type" == "vfat" ]] ||
    die "Expected a FAT filesystem, found: ${filesystem_type:-unknown}"

  [[ "$filesystem_label" == "$FILESYSTEM_LABEL" ]] ||
    die "Filesystem label does not match the expected value."

  [[ -n "$filesystem_uuid" ]] ||
    die "Filesystem UUID was not generated."
}

show_result() {
  printf '\nEFI System Partition formatted successfully.\n\n'

  lsblk \
    --output NAME,PATH,SIZE,TYPE,PARTTYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS \
    "$TARGET_PARTITION"

  printf '\nNext step:\n'
  printf '  08-mount-filesystems\n'
}

main() {
  require_root
  require_uefi
  require_commands
  parse_arguments "$@"

  canonicalize_partition
  validate_partition_type
  validate_partition_size
  validate_not_mounted
  validate_label
  show_target_summary
  confirm_destruction
  create_filesystem
  validate_filesystem
  show_result
}

main "$@"
