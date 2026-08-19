#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_BTRFS_DEVICE="/dev/mapper/cryptroot"
readonly DEFAULT_MOUNT_ROOT="/mnt"
readonly DEFAULT_MOUNT_OPTIONS="noatime,compress=zstd:3"
readonly LAYOUT_FILE="${REPO_ROOT}/system/storage/btrfs-layout.tsv"
readonly EFI_PARTITION_TYPE="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"

BTRFS_DEVICE="$DEFAULT_BTRFS_DEVICE"
EFI_PARTITION=""
MOUNT_ROOT="$DEFAULT_MOUNT_ROOT"
MOUNT_OPTIONS="$DEFAULT_MOUNT_OPTIONS"
INSTALLATION_COMPLETE=false

declare -a BTRFS_SUBVOLUMES=()
declare -a BTRFS_MOUNTPOINTS=()
declare -a MOUNTS_CREATED=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"
source "${REPO_ROOT}/scripts/lib/storage.sh"

setup_error_trap "$SCRIPT_NAME"

cleanup() {
  local exit_code=$?
  local index
  local target
  trap - EXIT INT TERM

  if [[ "$INSTALLATION_COMPLETE" == false ]]; then
    log_warn "Mount step did not complete. Unmounting filesystems created by this script."
    for ((index = ${#MOUNTS_CREATED[@]} - 1; index >= 0; index--)); do
      target="${MOUNTS_CREATED[$index]}"
      mountpoint --quiet "$target" && umount "$target" || true
    done
  fi
  exit "$exit_code"
}
trap cleanup EXIT INT TERM

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME --efi-partition /dev/<partition> [options]

Options:
  --btrfs-device <path>   Default: ${DEFAULT_BTRFS_DEVICE}
  --efi-partition <path>  Required EFI System Partition
  --mount-root <path>     Default: ${DEFAULT_MOUNT_ROOT}
  --mount-options <opts>  Default: ${DEFAULT_MOUNT_OPTIONS}
  --help, -h

Layout source:
  ${LAYOUT_FILE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --btrfs-device)
        (($# >= 2)) || die "Missing value for --btrfs-device."
        BTRFS_DEVICE="$2"
        shift 2
        ;;
      --efi-partition)
        (($# >= 2)) || die "Missing value for --efi-partition."
        EFI_PARTITION="$2"
        shift 2
        ;;
      --mount-root)
        (($# >= 2)) || die "Missing value for --mount-root."
        MOUNT_ROOT="$2"
        shift 2
        ;;
      --mount-options)
        (($# >= 2)) || die "Missing value for --mount-options."
        MOUNT_OPTIONS="$2"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
  [[ -n "$EFI_PARTITION" ]] || die "The --efi-partition argument is required."
}

validate_inputs() {
  BTRFS_DEVICE="$(canonicalize_existing_path "$BTRFS_DEVICE")"
  EFI_PARTITION="$(canonicalize_existing_path "$EFI_PARTITION")"
  [[ -b "$BTRFS_DEVICE" && -b "$EFI_PARTITION" ]] || die "Storage targets must be block devices."
  [[ "$BTRFS_DEVICE" != "$EFI_PARTITION" ]] || die "Btrfs and EFI devices cannot be the same device."
  [[ "$MOUNT_ROOT" == /* && "$MOUNT_ROOT" != "/" ]] || die "Mount root must be an absolute path other than /."
  mountpoint --quiet "$MOUNT_ROOT" && die "Mount root is already mounted: $MOUNT_ROOT"
  [[ ! -e "$MOUNT_ROOT" || -d "$MOUNT_ROOT" ]] || die "Mount root exists and is not a directory."

  if [[ -d "$MOUNT_ROOT" ]] && [[ -n "$(find "$MOUNT_ROOT" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    die "Mount root is not empty: $MOUNT_ROOT"
  fi

  [[ "$(lsblk --noheadings --nodeps --output FSTYPE "$BTRFS_DEVICE" | xargs)" == "btrfs" ]] ||
    die "Expected Btrfs on $BTRFS_DEVICE."
  [[ -z "$(findmnt --noheadings --source "$BTRFS_DEVICE" 2>/dev/null || true)" ]] || die "Btrfs device is already mounted."

  local efi_type
  local efi_fstype
  local efi_parttype
  efi_type="$(lsblk --noheadings --nodeps --output TYPE "$EFI_PARTITION" | xargs)"
  efi_fstype="$(lsblk --noheadings --nodeps --output FSTYPE "$EFI_PARTITION" | xargs)"
  efi_parttype="$(lsblk --noheadings --nodeps --output PARTTYPE "$EFI_PARTITION" | xargs | tr '[:lower:]' '[:upper:]')"
  [[ "$efi_type" == "part" ]] || die "EFI target must be a partition."
  [[ "$efi_fstype" == "vfat" ]] || die "Expected vfat on EFI partition."
  [[ "$efi_parttype" == "$EFI_PARTITION_TYPE" ]] || die "Target is not marked as an EFI System Partition."
  [[ -z "$(findmnt --noheadings --source "$EFI_PARTITION" 2>/dev/null || true)" ]] || die "EFI partition is already mounted."
}

mount_subvolume() {
  local subvolume="$1"
  local relative_mountpoint="$2"
  local target

  if [[ "$relative_mountpoint" == "/" ]]; then
    target="$MOUNT_ROOT"
  else
    target="${MOUNT_ROOT}${relative_mountpoint}"
  fi

  mkdir -p "$target"
  log_info "Mounting $subvolume at $target."
  mount --types btrfs --options "${MOUNT_OPTIONS},subvol=${subvolume}" "$BTRFS_DEVICE" "$target"
  MOUNTS_CREATED+=("$target")
  mountpoint --quiet "$target" || die "Mountpoint was not mounted successfully: $target"
}

mount_layout() {
  local index
  for ((index = 0; index < ${#BTRFS_SUBVOLUMES[@]}; index++)); do
    mount_subvolume "${BTRFS_SUBVOLUMES[$index]}" "${BTRFS_MOUNTPOINTS[$index]}"
  done
}

mount_efi() {
  local target="${MOUNT_ROOT}/boot"
  mkdir -p "$target"
  mount --types vfat "$EFI_PARTITION" "$target"
  MOUNTS_CREATED+=("$target")
  mountpoint --quiet "$target" || die "EFI System Partition was not mounted successfully."
}

validate_mount_tree() {
  local index
  local target
  local actual_subvolume
  local options

  for ((index = 0; index < ${#BTRFS_SUBVOLUMES[@]}; index++)); do
    if [[ "${BTRFS_MOUNTPOINTS[$index]}" == "/" ]]; then
      target="$MOUNT_ROOT"
    else
      target="${MOUNT_ROOT}${BTRFS_MOUNTPOINTS[$index]}"
    fi

    require_filesystem_type "$target" btrfs
    actual_subvolume="$(findmnt --noheadings --output FSROOT --target "$target" | xargs)"
    [[ "$actual_subvolume" == "/${BTRFS_SUBVOLUMES[$index]}" ]] || die "Unexpected subvolume mounted at $target."
    options="$(findmnt --noheadings --output OPTIONS --target "$target" | xargs)"
    [[ ",$options," == *",noatime,"* ]] || die "Mount option noatime is missing at $target."
    [[ ",$options," == *",compress=zstd:3,"* ]] || die "Mount option compress=zstd:3 is missing at $target."
  done

  require_filesystem_type "$MOUNT_ROOT/boot" vfat
}

show_plan() {
  printf '\nInstallation mount tree\n'
  printf '%s\n\n' '-----------------------'
  printf 'Btrfs device:\n  %s\n\n' "$BTRFS_DEVICE"
  printf 'EFI partition:\n  %s\n\n' "$EFI_PARTITION"
  printf 'Layout source:\n  %s\n\n' "$LAYOUT_FILE"
  printf 'Mounts:\n'
  local index
  for ((index = 0; index < ${#BTRFS_SUBVOLUMES[@]}; index++)); do
    printf '  %-12s -> %s\n' "${BTRFS_SUBVOLUMES[$index]}" "${BTRFS_MOUNTPOINTS[$index]}"
  done
}

confirm_mounting() {
  local confirmation
  printf '\nType MOUNT to create the installation mount tree: '
  read -r confirmation
  [[ "$confirmation" == "MOUNT" ]] || die "Filesystem mounting was not authorized."
}

show_result() {
  printf '\nInstallation filesystems mounted successfully.\n\n'
  findmnt --real --submounts "$MOUNT_ROOT"
  printf '\nNext step:\n  09-install-base-system\n'
}

main() {
  require_root
  require_commands find findmnt lsblk mkdir mount mountpoint readlink tr umount xargs
  parse_arguments "$@"
  load_btrfs_layout "$LAYOUT_FILE"
  validate_inputs
  show_plan
  confirm_mounting
  mount_layout
  mount_efi
  validate_mount_tree
  INSTALLATION_COMPLETE=true
  show_result
}

main "$@"
