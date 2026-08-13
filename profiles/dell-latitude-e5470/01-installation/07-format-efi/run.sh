#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly EXPECTED_PARTITION_TYPE="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
readonly DEFAULT_LABEL="EFI"

TARGET_PARTITION=""
FILESYSTEM_LABEL="$DEFAULT_LABEL"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME --partition /dev/<partition> [--label <label>]

Default label:
  ${DEFAULT_LABEL}

This operation permanently erases the selected partition.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --partition) (($# >= 2)) || die "Missing value for --partition."; TARGET_PARTITION="$2"; shift 2 ;;
      --label) (($# >= 2)) || die "Missing value for --label."; FILESYSTEM_LABEL="$2"; shift 2 ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
  [[ -n "$TARGET_PARTITION" ]] || die "The --partition argument is required."
}

validate_target() {
  TARGET_PARTITION="$(canonicalize_existing_path "$TARGET_PARTITION")"
  [[ -b "$TARGET_PARTITION" ]] || die "Target is not a block device: $TARGET_PARTITION"
  [[ "$(lsblk -dnro TYPE "$TARGET_PARTITION")" == "part" ]] || die "Target must be a partition: $TARGET_PARTITION"
  [[ "$(blockdev --getro "$TARGET_PARTITION")" == "0" ]] || die "Target partition is read-only: $TARGET_PARTITION"

  local actual_type
  actual_type="$(lsblk --noheadings --nodeps --output PARTTYPE "$TARGET_PARTITION" | xargs | tr '[:lower:]' '[:upper:]')"
  [[ "$actual_type" == "$EXPECTED_PARTITION_TYPE" ]] || die "Partition is not marked as an EFI System Partition."

  (( $(blockdev --getsize64 "$TARGET_PARTITION") >= 260 * 1024 * 1024 )) ||
    die "EFI System Partition must have at least 260 MiB."

  [[ -z "$(findmnt --noheadings --source "$TARGET_PARTITION" 2>/dev/null || true)" ]] ||
    die "Target partition is mounted and cannot be formatted."
  [[ -z "$(lsblk --noheadings --output MOUNTPOINTS "$TARGET_PARTITION" | sed '/^[[:space:]]*$/d')" ]] ||
    die "Target partition is mounted and cannot be formatted."

  [[ -n "$FILESYSTEM_LABEL" && ${#FILESYSTEM_LABEL} -le 11 ]] || die "FAT filesystem label is invalid."
  [[ "$FILESYSTEM_LABEL" =~ ^[A-Za-z0-9_-]+$ ]] || die "Filesystem label contains unsupported characters."
}

show_target_summary() {
  local parent
  local size
  parent="$(lsblk --noheadings --nodeps --output PKNAME "$TARGET_PARTITION" | xargs)"
  size="$(lsblk --noheadings --nodeps --output SIZE "$TARGET_PARTITION" | xargs)"

  printf '\nEFI System Partition formatting\n'
  printf '%s\n\n' '-------------------------------'
  printf 'Partition:\n  %s\n\n' "$TARGET_PARTITION"
  printf 'Parent:\n  /dev/%s\n\n' "$parent"
  printf 'Size:\n  %s\n\n' "$size"
  printf 'Label:\n  %s\n' "$FILESYSTEM_LABEL"
  printf '\nWARNING: ALL DATA ON %s WILL BE PERMANENTLY ERASED.\n' "$TARGET_PARTITION"
}

confirm_destruction() {
  local confirmed_partition
  local confirmation
  printf '\nType the complete target partition path to confirm: '
  read -r confirmed_partition
  [[ "$confirmed_partition" == "$TARGET_PARTITION" ]] || die "Target partition confirmation did not match."
  printf 'Type ERASE to authorize filesystem creation: '
  read -r confirmation
  [[ "$confirmation" == "ERASE" ]] || die "Destructive operation was not authorized."
}

create_filesystem() {
  log_info "Removing existing filesystem signatures."
  wipefs --all --force "$TARGET_PARTITION"
  log_info "Creating FAT32 filesystem."
  mkfs.fat -F 32 -n "$FILESYSTEM_LABEL" "$TARGET_PARTITION"
  udevadm settle
}

validate_filesystem() {
  [[ "$(lsblk --noheadings --nodeps --output FSTYPE "$TARGET_PARTITION" | xargs)" == "vfat" ]] || die "FAT filesystem was not created."
  [[ "$(lsblk --noheadings --nodeps --output LABEL "$TARGET_PARTITION" | xargs)" == "$FILESYSTEM_LABEL" ]] || die "Filesystem label does not match."
  [[ -n "$(lsblk --noheadings --nodeps --output UUID "$TARGET_PARTITION" | xargs)" ]] || die "Filesystem UUID was not generated."
}

show_result() {
  printf '\nEFI System Partition formatted successfully.\n\n'
  lsblk --output NAME,PATH,SIZE,TYPE,PARTTYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS "$TARGET_PARTITION"
  printf '\nNext step:\n  08-mount-filesystems\n'
}

main() {
  require_root
  require_uefi
  require_commands blockdev findmnt lsblk mkfs.fat readlink sed tr udevadm wipefs xargs
  parse_arguments "$@"
  validate_target
  show_target_summary
  confirm_destruction
  create_filesystem
  validate_filesystem
  show_result
}

main "$@"
