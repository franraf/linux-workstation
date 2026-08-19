#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly EXPECTED_PARTITION_TYPE="CA7D7CCB-63ED-4C53-861C-1742536059CC"
readonly MAPPER_NAME="cryptroot"
readonly MAPPER_PATH="/dev/mapper/${MAPPER_NAME}"

TARGET_PARTITION=""

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME --partition /dev/<partition>

Creates a LUKS2 container and opens it as:
  ${MAPPER_PATH}

WARNING: this operation permanently erases the selected partition.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --partition)
        (($# >= 2)) || die "Missing value for --partition."
        TARGET_PARTITION="$2"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
  [[ -n "$TARGET_PARTITION" ]] || die "The --partition argument is required."
}

validate_target() {
  TARGET_PARTITION="$(canonicalize_existing_path "$TARGET_PARTITION")"
  [[ -b "$TARGET_PARTITION" ]] || die "Target is not a block device: $TARGET_PARTITION"
  [[ "$(lsblk -dnro TYPE "$TARGET_PARTITION")" == "part" ]] || die "Target must be a partition."
  [[ "$(blockdev --getro "$TARGET_PARTITION")" == "0" ]] || die "Target partition is read-only."

  local actual_type
  actual_type="$(lsblk --noheadings --nodeps --output PARTTYPE "$TARGET_PARTITION" | xargs | tr '[:lower:]' '[:upper:]')"
  [[ "$actual_type" == "$EXPECTED_PARTITION_TYPE" ]] || die "Partition is not marked as Linux LUKS."

  [[ -z "$(lsblk --noheadings --output MOUNTPOINTS "$TARGET_PARTITION" | sed '/^[[:space:]]*$/d')" ]] ||
    die "Target partition is mounted and cannot be formatted."

  local holder_directory
  holder_directory="/sys/class/block/$(basename "$TARGET_PARTITION")/holders"
  local holder_count=0
  [[ ! -d "$holder_directory" ]] || holder_count="$(find "$holder_directory" -mindepth 1 -maxdepth 1 | wc -l)"
  ((holder_count == 0)) || die "Target partition has active device-mapper holders."

  [[ ! -e "$MAPPER_PATH" ]] || die "Mapper already exists: $MAPPER_PATH"
  cryptsetup status "$MAPPER_NAME" >/dev/null 2>&1 && die "Mapper name is already active: $MAPPER_NAME"
  cryptsetup isLuks "$TARGET_PARTITION" >/dev/null 2>&1 && die "Target partition already contains a LUKS header."
}

show_target_summary() {
  local parent
  parent="$(lsblk --noheadings --nodeps --output PKNAME "$TARGET_PARTITION" | xargs)"
  printf '\nLUKS2 container creation\n'
  printf '%s\n\n' '------------------------'
  printf 'Partition:\n  %s\n\n' "$TARGET_PARTITION"
  printf 'Parent:\n  /dev/%s\n\n' "$parent"
  printf 'Size:\n  %s\n\n' "$(lsblk --noheadings --nodeps --output SIZE "$TARGET_PARTITION" | xargs)"
  printf 'Mapper:\n  %s\n' "$MAPPER_PATH"
  printf '\nWARNING: ALL DATA ON %s WILL BE PERMANENTLY ERASED.\n' "$TARGET_PARTITION"
}

confirm_destruction() {
  local confirmed_partition
  local confirmation
  printf '\nType the complete target partition path to confirm: '
  read -r confirmed_partition
  [[ "$confirmed_partition" == "$TARGET_PARTITION" ]] || die "Target partition confirmation did not match."
  printf 'Type ERASE to authorize permanent data destruction: '
  read -r confirmation
  [[ "$confirmation" == "ERASE" ]] || die "Destructive operation was not authorized."
}

create_luks_container() {
  log_warn "cryptsetup will request the new LUKS passphrase interactively."
  cryptsetup --type luks2 --verify-passphrase luksFormat "$TARGET_PARTITION"
}

validate_luks_container() {
  cryptsetup isLuks "$TARGET_PARTITION" || die "The target partition does not contain a valid LUKS header."
  local version
  version="$(cryptsetup luksDump "$TARGET_PARTITION" | awk -F: '/^Version:/ { gsub(/[[:space:]]/, "", $2); print $2; exit }')"
  [[ "$version" == "2" ]] || die "Expected LUKS version 2, found: ${version:-unknown}"
}

open_luks_container() {
  log_warn "cryptsetup will request the LUKS passphrase to open the container."
  cryptsetup open --type luks2 "$TARGET_PARTITION" "$MAPPER_NAME"
  udevadm settle
}

validate_mapping() {
  [[ -b "$MAPPER_PATH" ]] || die "Mapped device was not created: $MAPPER_PATH"
  cryptsetup status "$MAPPER_NAME" >/dev/null || die "Mapped device is not reported as active."
  local backing_device
  backing_device="$(cryptsetup status "$MAPPER_NAME" | awk -F: '/^[[:space:]]*device:/ { sub(/^[[:space:]]+/, "", $2); print $2; exit }')"
  backing_device="$(readlink -f "$backing_device")"
  [[ "$backing_device" == "$TARGET_PARTITION" ]] || die "Mapper does not reference the expected target partition."
}

show_result() {
  printf '\nLUKS2 container created and opened successfully.\n\n'
  cryptsetup status "$MAPPER_NAME"
  printf '\nNext step:\n  05-create-btrfs\n'
}

main() {
  require_root
  require_commands awk basename blockdev cryptsetup find lsblk readlink sed tr udevadm wc xargs
  parse_arguments "$@"
  validate_target
  show_target_summary
  confirm_destruction
  create_luks_container
  validate_luks_container
  open_luks_container
  validate_mapping
  show_result
}

main "$@"
