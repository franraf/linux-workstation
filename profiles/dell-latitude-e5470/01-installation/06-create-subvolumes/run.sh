#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly DEFAULT_DEVICE="/dev/mapper/cryptroot"
readonly DEFAULT_MOUNTPOINT="/mnt/btrfs-root"
readonly LAYOUT_FILE="${REPO_ROOT}/system/storage/btrfs-layout.tsv"

TARGET_DEVICE="$DEFAULT_DEVICE"
TEMP_MOUNTPOINT="$DEFAULT_MOUNTPOINT"
MOUNTED_BY_SCRIPT=false

declare -a BTRFS_SUBVOLUMES=()
declare -a BTRFS_MOUNTPOINTS=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"
source "${REPO_ROOT}/scripts/lib/storage.sh"

setup_error_trap "$SCRIPT_NAME"

cleanup() {
  local exit_code=$?
  trap - EXIT INT TERM

  if [[ "$MOUNTED_BY_SCRIPT" == true ]] && mountpoint --quiet "$TEMP_MOUNTPOINT"; then
    log_info "Unmounting temporary Btrfs mount."
    umount "$TEMP_MOUNTPOINT" || log_warn "Unable to unmount temporary mountpoint: $TEMP_MOUNTPOINT"
  fi

  [[ ! -d "$TEMP_MOUNTPOINT" ]] || rmdir "$TEMP_MOUNTPOINT" 2>/dev/null || true
  exit "$exit_code"
}
trap cleanup EXIT INT TERM

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [options]

Options:
  --device <path>       Btrfs block device. Default: ${DEFAULT_DEVICE}
  --mountpoint <path>   Temporary mountpoint. Default: ${DEFAULT_MOUNTPOINT}
  --help, -h            Show this help message.

Layout source:
  ${LAYOUT_FILE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --device) (($# >= 2)) || die "Missing value for --device."; TARGET_DEVICE="$2"; shift 2 ;;
      --mountpoint) (($# >= 2)) || die "Missing value for --mountpoint."; TEMP_MOUNTPOINT="$2"; shift 2 ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

validate_inputs() {
  TARGET_DEVICE="$(canonicalize_existing_path "$TARGET_DEVICE")"
  [[ -b "$TARGET_DEVICE" ]] || die "Target is not a block device: $TARGET_DEVICE"
  [[ "$TEMP_MOUNTPOINT" == /* && "$TEMP_MOUNTPOINT" != "/" && "$TEMP_MOUNTPOINT" != "/mnt" ]] ||
    die "Temporary mountpoint must be an absolute path other than / or /mnt."
  mountpoint --quiet "$TEMP_MOUNTPOINT" && die "Temporary mountpoint is already in use: $TEMP_MOUNTPOINT"
  [[ ! -e "$TEMP_MOUNTPOINT" || -d "$TEMP_MOUNTPOINT" ]] || die "Temporary mountpoint exists and is not a directory."

  if [[ -d "$TEMP_MOUNTPOINT" ]] && [[ -n "$(find "$TEMP_MOUNTPOINT" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    die "Temporary mountpoint is not empty: $TEMP_MOUNTPOINT"
  fi

  [[ "$(lsblk --noheadings --nodeps --output FSTYPE "$TARGET_DEVICE" | xargs)" == "btrfs" ]] ||
    die "Target device does not contain a Btrfs filesystem."
  [[ -z "$(findmnt --noheadings --raw --source "$TARGET_DEVICE" --output TARGET 2>/dev/null || true)" ]] ||
    die "Target device is already mounted."
}

mount_top_level() {
  mkdir -p "$TEMP_MOUNTPOINT"
  mount --types btrfs --options subvolid=5 "$TARGET_DEVICE" "$TEMP_MOUNTPOINT"
  MOUNTED_BY_SCRIPT=true
  mountpoint --quiet "$TEMP_MOUNTPOINT" || die "Temporary mountpoint was not mounted successfully."
}

validate_initial_state() {
  local existing
  existing="$(btrfs subvolume list -o "$TEMP_MOUNTPOINT" 2>/dev/null || true)"
  [[ -z "$existing" ]] || die "Refusing to modify a Btrfs filesystem that already has subvolumes."
}

show_plan() {
  printf '\nBtrfs subvolume creation\n'
  printf '%s\n\n' '------------------------'
  printf 'Device:\n  %s\n\n' "$TARGET_DEVICE"
  printf 'Layout source:\n  %s\n\n' "$LAYOUT_FILE"
  printf 'Subvolumes:\n'
  printf '  - %s\n' "${BTRFS_SUBVOLUMES[@]}"
}

confirm_creation() {
  local confirmation
  printf '\nType CREATE to create the subvolume structure: '
  read -r confirmation
  [[ "$confirmation" == "CREATE" ]] || die "Subvolume creation was not authorized."
}

create_subvolumes() {
  local subvolume
  for subvolume in "${BTRFS_SUBVOLUMES[@]}"; do
    log_info "Creating subvolume: $subvolume"
    btrfs subvolume create "$TEMP_MOUNTPOINT/$subvolume"
  done
}

validate_subvolumes() {
  local subvolume
  for subvolume in "${BTRFS_SUBVOLUMES[@]}"; do
    btrfs subvolume show "$TEMP_MOUNTPOINT/$subvolume" >/dev/null ||
      die "Path is not a valid Btrfs subvolume: $subvolume"
  done

  local actual_count
  actual_count="$(btrfs subvolume list -o "$TEMP_MOUNTPOINT" | wc -l)"
  ((actual_count == ${#BTRFS_SUBVOLUMES[@]})) ||
    die "Expected ${#BTRFS_SUBVOLUMES[@]} subvolumes, found $actual_count."
}

show_result() {
  printf '\nBtrfs subvolumes created successfully.\n\n'
  btrfs subvolume list --sort=path "$TEMP_MOUNTPOINT"
  printf '\nNext step:\n  07-format-efi\n'
}

main() {
  require_root
  require_commands btrfs find findmnt lsblk mkdir mount mountpoint readlink rmdir umount wc xargs
  parse_arguments "$@"
  load_btrfs_layout "$LAYOUT_FILE"
  validate_inputs
  mount_top_level
  validate_initial_state
  show_plan
  confirm_creation
  create_subvolumes
  validate_subvolumes
  show_result
}

main "$@"
