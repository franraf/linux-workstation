#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_DEVICE="/dev/mapper/cryptroot"
readonly DEFAULT_LABEL="linux-workstation"

TARGET_DEVICE="$DEFAULT_DEVICE"
MAPPER_NAME=""
FILESYSTEM_LABEL="$DEFAULT_LABEL"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [options]

Options:
  --device <path>  Default: ${DEFAULT_DEVICE}
  --label <label>  Default: ${DEFAULT_LABEL}
  --help, -h

This operation permanently erases filesystem data on the mapped device.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --device)
        (($# >= 2)) || die "Missing value for --device."
        TARGET_DEVICE="$2"
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
      *) die "Unknown argument: $1" ;;
    esac
  done
}

validate_target() {
  TARGET_DEVICE="$(canonicalize_existing_path "$TARGET_DEVICE")"
  [[ -b "$TARGET_DEVICE" ]] || die "Target is not a block device: $TARGET_DEVICE"
  [[ "$(blockdev --getro "$TARGET_DEVICE")" == "0" ]] || die "Target device is read-only: $TARGET_DEVICE"
  MAPPER_NAME="$(basename "$TARGET_DEVICE")"

  [[ -n "$FILESYSTEM_LABEL" && "$FILESYSTEM_LABEL" != *$'\n'* ]] || die "Filesystem label is invalid."
  ((${#FILESYSTEM_LABEL} <= 256)) || die "Filesystem label exceeds the Btrfs label limit."

  [[ "$(lsblk --noheadings --nodeps --output TYPE "$TARGET_DEVICE" | xargs)" == "crypt" ]] ||
    die "Target must be an active encrypted mapping: $TARGET_DEVICE"
  cryptsetup status "$MAPPER_NAME" >/dev/null 2>&1 || die "Target is not an active cryptsetup mapping: $TARGET_DEVICE"

  local backing_device
  backing_device="$(cryptsetup status "$MAPPER_NAME" | awk '$1 == "device:" { print $2; exit }')"
  [[ -n "$backing_device" && -b "$backing_device" ]] || die "Unable to validate backing device for $TARGET_DEVICE"

  [[ -z "$(findmnt --noheadings --source "$TARGET_DEVICE" 2>/dev/null || true)" ]] || die "Target device is mounted."
  [[ -z "$(lsblk --noheadings --output MOUNTPOINTS "$TARGET_DEVICE" | sed '/^[[:space:]]*$/d')" ]] ||
    die "Target device or one of its descendants is mounted."

  local child_count
  child_count="$(lsblk --noheadings --output TYPE "$TARGET_DEVICE" | awk 'NR > 1 { count++ } END { print count + 0 }')"
  ((child_count == 0)) || die "Target device has unexpected child devices."
  (($(blockdev --getsize64 "$TARGET_DEVICE") >= 4 * 1024 * 1024 * 1024)) || die "Target device must have at least 4 GiB."
}

show_target_summary() {
  local backing_device
  local size
  local signatures
  backing_device="$(cryptsetup status "$MAPPER_NAME" | awk -F: '/^[[:space:]]*device:/ { sub(/^[[:space:]]+/, "", $2); print $2; exit }')"
  backing_device="$(readlink -f "$backing_device")"
  size="$(lsblk --noheadings --nodeps --output SIZE "$TARGET_DEVICE" | xargs)"
  signatures="$(wipefs --noheadings "$TARGET_DEVICE" 2>/dev/null || true)"

  printf '\nBtrfs filesystem creation\n'
  printf '%s\n\n' '--------------------------'
  printf 'Mapped device:\n  %s\n\n' "$TARGET_DEVICE"
  printf 'Backing device:\n  %s\n\n' "$backing_device"
  printf 'Size:\n  %s\n\n' "$size"
  printf 'Label:\n  %s\n' "$FILESYSTEM_LABEL"
  [[ -z "$signatures" ]] || printf '\nExisting signatures:\n%s\n' "$signatures"
  printf '\nWARNING: ALL FILESYSTEM DATA ON %s WILL BE PERMANENTLY ERASED.\n' "$TARGET_DEVICE"
}

confirm_destruction() {
  local confirmed_device
  local confirmation
  printf '\nType the complete mapped device path to confirm: '
  read -r confirmed_device
  [[ "$confirmed_device" == "$TARGET_DEVICE" ]] || die "Target device confirmation did not match."
  printf 'Type ERASE to authorize filesystem creation: '
  read -r confirmation
  [[ "$confirmation" == "ERASE" ]] || die "Destructive operation was not authorized."
}

create_filesystem() {
  log_info "Creating Btrfs filesystem on $TARGET_DEVICE."
  mkfs.btrfs --force --label "$FILESYSTEM_LABEL" "$TARGET_DEVICE"
  udevadm settle
}

validate_filesystem() {
  [[ "$(lsblk --noheadings --nodeps --output FSTYPE "$TARGET_DEVICE" | xargs)" == "btrfs" ]] || die "Btrfs filesystem was not created."
  [[ "$(lsblk --noheadings --nodeps --output LABEL "$TARGET_DEVICE" | xargs)" == "$FILESYSTEM_LABEL" ]] || die "Filesystem label does not match."
  [[ -n "$(lsblk --noheadings --nodeps --output UUID "$TARGET_DEVICE" | xargs)" ]] || die "Filesystem UUID was not generated."
}

show_result() {
  printf '\nBtrfs filesystem created successfully.\n\n'
  lsblk --output NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS "$TARGET_DEVICE"
  printf '\nNext step:\n  06-create-subvolumes\n'
}

main() {
  require_root
  require_commands awk basename blockdev cryptsetup findmnt lsblk mkfs.btrfs readlink sed udevadm wipefs xargs
  parse_arguments "$@"
  validate_target
  show_target_summary
  confirm_destruction
  create_filesystem
  validate_filesystem
  show_result
}

main "$@"
