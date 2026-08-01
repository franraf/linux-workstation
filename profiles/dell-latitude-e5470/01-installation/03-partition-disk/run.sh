```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly EFI_SIZE="1GiB"

readonly EFI_PARTITION_TYPE="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
readonly LUKS_PARTITION_TYPE="CA7D7CCB-63ED-4C53-861C-1742536059CC"

TARGET_DISK=""

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
  sudo ./$SCRIPT_NAME --disk /dev/<device>

Example:
  sudo ./$SCRIPT_NAME --disk /dev/sda

This operation permanently erases the selected disk and creates:

  1. EFI System Partition: ${EFI_SIZE}
  2. Linux LUKS partition: remaining space
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] || die "This script must be executed as root."
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
    sfdisk
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
      --disk)
        (($# >= 2)) || die "Missing value for --disk."
        TARGET_DISK="$2"
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

  [[ -n "$TARGET_DISK" ]] || die "The --disk argument is required."
}

canonicalize_disk() {
  TARGET_DISK="$(readlink -f "$TARGET_DISK")"

  [[ -b "$TARGET_DISK" ]] ||
    die "Target is not a block device: $TARGET_DISK"

  [[ "$(lsblk -dnro TYPE "$TARGET_DISK")" == "disk" ]] ||
    die "Target must be a whole disk, not a partition: $TARGET_DISK"

  [[ "$(blockdev --getro "$TARGET_DISK")" == "0" ]] ||
    die "Target disk is read-only: $TARGET_DISK"
}

show_available_disks() {
  log "Available disks:"

  lsblk \
    --nodeps \
    --output NAME,PATH,SIZE,MODEL,SERIAL,TRAN,ROTA,TYPE
}

validate_disk_size() {
  local disk_size_bytes
  local minimum_size_bytes=$((8 * 1024 * 1024 * 1024))

  disk_size_bytes="$(blockdev --getsize64 "$TARGET_DISK")"

  ((disk_size_bytes >= minimum_size_bytes)) ||
    die "Target disk must have at least 8 GiB."
}

validate_not_in_use() {
  local device
  local mountpoints
  local swap_devices

  while read -r device; do
    mountpoints="$(
      lsblk \
        --noheadings \
        --output MOUNTPOINTS \
        "$device" |
        sed '/^[[:space:]]*$/d'
    )"

    [[ -z "$mountpoints" ]] ||
      die "Device is mounted and cannot be erased: $device"
  done < <(lsblk --noheadings --paths --output NAME "$TARGET_DISK")

  swap_devices="$(swapon --noheadings --raw --show=NAME 2>/dev/null || true)"

  while read -r device; do
    [[ -z "$device" ]] && continue

    if grep -Fxq "$device" <<<"$swap_devices"; then
      die "Device is active as swap and cannot be erased: $device"
    fi
  done < <(lsblk --noheadings --paths --output NAME "$TARGET_DISK")
}

validate_not_running_system_disk() {
  local root_source
  local root_parent

  root_source="$(findmnt --noheadings --output SOURCE / 2>/dev/null || true)"

  [[ "$root_source" == /dev/* ]] || return 0

  root_parent="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output PKNAME \
      "$root_source" 2>/dev/null |
      xargs
  )"

  if [[ -n "$root_parent" ]]; then
    root_parent="/dev/$root_parent"
  else
    root_parent="$(readlink -f "$root_source")"
  fi

  [[ "$TARGET_DISK" != "$root_parent" ]] ||
    die "Refusing to erase the disk containing the running root filesystem."
}

show_target_summary() {
  local model
  local serial
  local size

  model="$(lsblk -dnro MODEL "$TARGET_DISK" | xargs)"
  serial="$(lsblk -dnro SERIAL "$TARGET_DISK" | xargs)"
  size="$(lsblk -dnro SIZE "$TARGET_DISK" | xargs)"

  cat <<EOF

Target disk
-----------

Device: $TARGET_DISK
Size:   ${size:-unknown}
Model:  ${model:-unknown}
Serial: ${serial:-unknown}

Partition layout
----------------

1. EFI System Partition
   Size: ${EFI_SIZE}
   Type: EFI System

2. Encrypted system partition
   Size: remaining space
   Type: Linux LUKS

WARNING: ALL DATA ON $TARGET_DISK WILL BE PERMANENTLY ERASED.
EOF
}

confirm_destruction() {
  local confirmation
  local confirmed_disk

  printf '\nType the complete target disk path to confirm: '
  read -r confirmed_disk

  [[ "$confirmed_disk" == "$TARGET_DISK" ]] ||
    die "Target disk confirmation did not match."

  printf 'Type ERASE to authorize permanent data destruction: '
  read -r confirmation

  [[ "$confirmation" == "ERASE" ]] ||
    die "Destructive operation was not authorized."
}

wipe_existing_signatures() {
  local device

  log "Removing existing filesystem and partition signatures."

  mapfile -t devices < <(
    lsblk \
      --noheadings \
      --paths \
      --output NAME \
      "$TARGET_DISK" |
      tac
  )

  for device in "${devices[@]}"; do
    wipefs --all --force "$device"
  done
}

create_partition_table() {
  log "Creating GPT partition table."

  sfdisk \
    --wipe always \
    --wipe-partitions always \
    "$TARGET_DISK" <<EOF
label: gpt
unit: sectors

size=${EFI_SIZE}, type=${EFI_PARTITION_TYPE}, name="EFI System"
type=${LUKS_PARTITION_TYPE}, name="Linux LUKS"
EOF

  blockdev --rereadpt "$TARGET_DISK" || true
  udevadm settle
}

validate_partition_table() {
  local partition_table_type
  local partition_count
  local efi_count
  local luks_count

  partition_table_type="$(lsblk -dnro PTTYPE "$TARGET_DISK")"

  [[ "$partition_table_type" == "gpt" ]] ||
    die "Expected GPT partition table, found: $partition_table_type"

  partition_count="$(
    lsblk \
      --noheadings \
      --output TYPE \
      "$TARGET_DISK" |
      awk '$1 == "part" { count++ } END { print count + 0 }'
  )"

  [[ "$partition_count" == "2" ]] ||
    die "Expected exactly 2 partitions, found: $partition_count"

  efi_count="$(
    lsblk \
      --noheadings \
      --output PARTTYPE \
      "$TARGET_DISK" |
      tr '[:lower:]' '[:upper:]' |
      grep -c "^${EFI_PARTITION_TYPE}$" || true
  )"

  luks_count="$(
    lsblk \
      --noheadings \
      --output PARTTYPE \
      "$TARGET_DISK" |
      tr '[:lower:]' '[:upper:]' |
      grep -c "^${LUKS_PARTITION_TYPE}$" || true
  )"

  [[ "$efi_count" == "1" ]] ||
    die "Expected exactly one EFI System Partition."

  [[ "$luks_count" == "1" ]] ||
    die "Expected exactly one Linux LUKS partition."
}

show_result() {
  printf '\nPartitioning completed successfully.\n\n'

  lsblk \
    --output NAME,PATH,SIZE,TYPE,PTTYPE,PARTTYPE,PARTLABEL \
    "$TARGET_DISK"

  printf '\nNext step:\n'
  printf '  04-create-luks\n'
}

main() {
  require_root
  require_uefi
  require_commands
  parse_arguments "$@"

  show_available_disks
  canonicalize_disk
  validate_disk_size
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
```
