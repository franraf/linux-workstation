#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly EFI_SIZE="1GiB"
readonly EFI_PARTITION_TYPE="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
readonly LUKS_PARTITION_TYPE="CA7D7CCB-63ED-4C53-861C-1742536059CC"

TARGET_DISK=""

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME --disk /dev/<device>

Creates:
  1. EFI System Partition: ${EFI_SIZE}
  2. Linux LUKS partition: remaining space

WARNING: this operation permanently erases the selected disk.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --disk) (($# >= 2)) || die "Missing value for --disk."; TARGET_DISK="$2"; shift 2 ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
  [[ -n "$TARGET_DISK" ]] || die "The --disk argument is required."
}

validate_target_disk() {
  TARGET_DISK="$(canonicalize_existing_path "$TARGET_DISK")"
  [[ -b "$TARGET_DISK" ]] || die "Target is not a block device: $TARGET_DISK"
  [[ "$(lsblk -dnro TYPE "$TARGET_DISK")" == "disk" ]] || die "Target must be a whole disk, not a partition."
  [[ "$(blockdev --getro "$TARGET_DISK")" == "0" ]] || die "Target disk is read-only."
  (( $(blockdev --getsize64 "$TARGET_DISK") >= 8 * 1024 * 1024 * 1024 )) || die "Target disk must have at least 8 GiB."
}

validate_not_in_use() {
  local device
  local mountpoints
  local swap_devices
  swap_devices="$(swapon --noheadings --raw --show=NAME 2>/dev/null || true)"

  while read -r device; do
    [[ -n "$device" ]] || continue
    mountpoints="$(lsblk --list --noheadings --output MOUNTPOINTS "$device" | sed '/^[[:space:]]*$/d')"
    [[ -z "$mountpoints" ]] || die "Device is mounted and cannot be erased: $device"
    if [[ -n "$swap_devices" ]] && grep -Fxq "$device" <<<"$swap_devices"; then
      die "Device is active as swap and cannot be erased: $device"
    fi
  done < <(lsblk --noheadings --list --paths --output NAME "$TARGET_DISK")
}

validate_not_running_system_disk() {
  local root_source
  local parent_name
  local root_disk
  root_source="$(findmnt --noheadings --output SOURCE / 2>/dev/null || true)"
  [[ "$root_source" == /dev/* ]] || return 0

  parent_name="$(lsblk --noheadings --nodeps --output PKNAME "$root_source" 2>/dev/null | xargs)"
  if [[ -n "$parent_name" ]]; then
    root_disk="/dev/$parent_name"
  else
    root_disk="$(readlink -f "$root_source")"
  fi

  [[ "$TARGET_DISK" != "$root_disk" ]] || die "Refusing to erase the disk containing the running root filesystem."
}

show_target_summary() {
  printf '\nDisk partitioning\n'
  printf '%s\n\n' '-----------------'
  printf 'Device:\n  %s\n\n' "$TARGET_DISK"
  printf 'Size:\n  %s\n\n' "$(lsblk -dnro SIZE "$TARGET_DISK" | xargs)"
  printf 'Model:\n  %s\n\n' "$(lsblk -dnro MODEL "$TARGET_DISK" | xargs)"
  printf 'Serial:\n  %s\n\n' "$(lsblk -dnro SERIAL "$TARGET_DISK" | xargs)"
  printf 'Layout:\n  EFI %s + LUKS remaining space\n' "$EFI_SIZE"
  printf '\nWARNING: ALL DATA ON %s WILL BE PERMANENTLY ERASED.\n' "$TARGET_DISK"
}

confirm_destruction() {
  local confirmed_disk
  local confirmation
  printf '\nType the complete target disk path to confirm: '
  read -r confirmed_disk
  [[ "$confirmed_disk" == "$TARGET_DISK" ]] || die "Target disk confirmation did not match."
  printf 'Type ERASE to authorize permanent data destruction: '
  read -r confirmation
  [[ "$confirmation" == "ERASE" ]] || die "Destructive operation was not authorized."
}

wipe_existing_signatures() {
  local device
  local -a devices=()
  mapfile -t devices < <(lsblk --noheadings --list --paths --output NAME "$TARGET_DISK" | tac)
  for device in "${devices[@]}"; do
    wipefs --all --force "$device"
  done
}

create_partition_table() {
  sfdisk --wipe always --wipe-partitions always "$TARGET_DISK" <<EOF
label: gpt
unit: sectors

size=${EFI_SIZE}, type=${EFI_PARTITION_TYPE}, name="EFI System"
type=${LUKS_PARTITION_TYPE}, name="Linux LUKS"
EOF
  blockdev --rereadpt "$TARGET_DISK" || true
  udevadm settle
}

validate_partition_table() {
  [[ "$(lsblk -dnro PTTYPE "$TARGET_DISK")" == "gpt" ]] || die "Expected GPT partition table."
  local partition_count
  partition_count="$(lsblk --list --noheadings --output TYPE "$TARGET_DISK" | awk '$1 == "part" { count++ } END { print count + 0 }')"
  [[ "$partition_count" == "2" ]] || die "Expected exactly 2 partitions, found: $partition_count"

  local efi_count
  local luks_count
  efi_count="$(lsblk --list --noheadings --output PARTTYPE "$TARGET_DISK" | tr '[:lower:]' '[:upper:]' | grep -c "^${EFI_PARTITION_TYPE}$" || true)"
  luks_count="$(lsblk --list --noheadings --output PARTTYPE "$TARGET_DISK" | tr '[:lower:]' '[:upper:]' | grep -c "^${LUKS_PARTITION_TYPE}$" || true)"
  [[ "$efi_count" == "1" ]] || die "Expected exactly one EFI System Partition."
  [[ "$luks_count" == "1" ]] || die "Expected exactly one Linux LUKS partition."
}

show_result() {
  printf '\nPartitioning completed successfully.\n\n'
  lsblk --output NAME,PATH,SIZE,TYPE,PTTYPE,PARTTYPE,PARTLABEL "$TARGET_DISK"
  printf '\nNext step:\n  04-create-luks\n'
}

main() {
  require_root
  require_uefi
  require_commands awk blockdev findmnt grep lsblk readlink sed sfdisk swapon tac tr udevadm wipefs xargs
  parse_arguments "$@"
  validate_target_disk
  validate_not_in_use
  validate_not_running_system_disk
  show_target_summary
  confirm_destruction
  wipe_existing_signatures
  create_partition_table
  validate_partition_table
  show_result
}

main "$@"
