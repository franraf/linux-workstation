#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly DEFAULT_TARGET_ROOT="/mnt"
readonly LAYOUT_FILE="${REPO_ROOT}/system/storage/btrfs-layout.tsv"

TARGET_ROOT="$DEFAULT_TARGET_ROOT"
FSTAB_PATH=""

declare -a BTRFS_SUBVOLUMES=()
declare -a BTRFS_MOUNTPOINTS=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"
source "${REPO_ROOT}/scripts/lib/storage.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [--root <path>]

Default target root:
  ${DEFAULT_TARGET_ROOT}

Layout source:
  ${LAYOUT_FILE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --root) (($# >= 2)) || die "Missing value for --root."; TARGET_ROOT="$2"; shift 2 ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

canonicalize_paths() {
  TARGET_ROOT="$(canonicalize_existing_path "$TARGET_ROOT")"
  FSTAB_PATH="${TARGET_ROOT}/etc/fstab"
}

validate_target() {
  require_btrfs_root_subvolume "$TARGET_ROOT" "/@"
  require_arch_target_system "$TARGET_ROOT"
  require_mountpoints "$TARGET_ROOT" "${BTRFS_MOUNTPOINTS[@]}" /boot
  require_filesystem_type "$TARGET_ROOT/boot" vfat
}

validate_mount_sources() {
  local root_source
  local root_device
  local mountpoint
  local source
  local source_device
  local target

  root_source="$(findmnt --noheadings --output SOURCE --target "$TARGET_ROOT" | xargs)"
  root_device="${root_source%%\[*}"
  [[ -b "$root_device" ]] || die "Unable to determine the root block device: $root_device"

  for mountpoint in "${BTRFS_MOUNTPOINTS[@]}"; do
    [[ "$mountpoint" == "/" ]] && continue
    target="${TARGET_ROOT}${mountpoint}"
    source="$(findmnt --noheadings --output SOURCE --target "$target" | xargs)"
    source_device="${source%%\[*}"
    [[ "$source_device" == "$root_device" ]] || die "Unexpected source mounted at $target."
  done
}

validate_existing_fstab() {
  if [[ -e "$FSTAB_PATH" && -s "$FSTAB_PATH" ]]; then
    die "A non-empty fstab already exists: $FSTAB_PATH"
  fi
}

show_plan() {
  printf '\nfstab generation\n'
  printf '%s\n\n' '----------------'
  printf 'Target root:\n  %s\n\n' "$TARGET_ROOT"
  printf 'Output:\n  %s\n\n' "$FSTAB_PATH"
  printf 'Layout source:\n  %s\n\n' "$LAYOUT_FILE"
  printf 'Expected mountpoints:\n'
  printf '  - %s\n' "${BTRFS_MOUNTPOINTS[@]}" /boot
}

confirm_generation() {
  local confirmation
  printf '\nType GENERATE to create the target fstab: '
  read -r confirmation
  [[ "$confirmation" == "GENERATE" ]] || die "fstab generation was not authorized."
}

generate_fstab() {
  local temporary_file
  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  genfstab -U "$TARGET_ROOT" >"$temporary_file"
  [[ -s "$temporary_file" ]] || die "genfstab produced an empty file."
  install --mode 0644 "$temporary_file" "$FSTAB_PATH"

  rm -f "$temporary_file"
  trap - RETURN
}

get_fstab_mountpoints() {
  awk '!/^[[:space:]]*#/ && NF >= 2 { print $2 }' "$FSTAB_PATH"
}

validate_fstab_entries() {
  local actual_mountpoints
  local mountpoint
  local duplicates
  local invalid_sources
  local expected_count=$((${#BTRFS_MOUNTPOINTS[@]} + 1))
  local actual_count

  actual_mountpoints="$(get_fstab_mountpoints)"

  for mountpoint in "${BTRFS_MOUNTPOINTS[@]}" /boot; do
    grep -Fxq "$mountpoint" <<<"$actual_mountpoints" || die "Expected fstab mountpoint is missing: $mountpoint"
  done

  actual_count="$(sed '/^[[:space:]]*$/d' <<<"$actual_mountpoints" | wc -l)"
  ((actual_count == expected_count)) || die "Expected $expected_count fstab entries, found $actual_count."

  duplicates="$(sort <<<"$actual_mountpoints" | uniq -d)"
  [[ -z "$duplicates" ]] || die "Duplicate mountpoints found in fstab: $duplicates"

  invalid_sources="$(awk '!/^[[:space:]]*#/ && NF >= 2 && $1 !~ /^UUID=/ { print $1 }' "$FSTAB_PATH")"
  [[ -z "$invalid_sources" ]] || die "Non-UUID sources found in fstab: $invalid_sources"
}

validate_btrfs_entries() {
  local index
  local mountpoint
  local subvolume

  for ((index = 0; index < ${#BTRFS_SUBVOLUMES[@]}; index++)); do
    mountpoint="${BTRFS_MOUNTPOINTS[$index]}"
    subvolume="${BTRFS_SUBVOLUMES[$index]}"

    awk -v target="$mountpoint" -v expected="subvol=/${subvolume}" '
      !/^[[:space:]]*#/ && $2 == target {
        opts = "," $4 ","
        if ($3 != "btrfs") exit 1
        if (opts !~ /,noatime,/) exit 2
        if (opts !~ /,compress=zstd:3,/) exit 3
        if (index(opts, "," expected ",") == 0) exit 4
        found = 1
      }
      END { if (!found) exit 5 }
    ' "$FSTAB_PATH" || die "Invalid Btrfs entry for mountpoint: $mountpoint"
  done
}

validate_efi_entry() {
  awk '!/^[[:space:]]*#/ && $2 == "/boot" { if ($3 != "vfat") exit 1; found = 1 } END { if (!found) exit 2 }' \
    "$FSTAB_PATH" || die "Invalid EFI System Partition entry."
}

validate_mount_simulation() {
  mount --fake --all --fstab "$FSTAB_PATH"
}

show_result() {
  printf '\nfstab generated successfully.\n\n'
  cat "$FSTAB_PATH"
  printf '\nNext step:\n  11-enter-chroot\n'
}

main() {
  require_root
  require_commands awk cat findmnt genfstab grep install mktemp mount readlink sed sort uniq wc xargs
  parse_arguments "$@"
  load_btrfs_layout "$LAYOUT_FILE"
  canonicalize_paths
  validate_target
  validate_mount_sources
  validate_existing_fstab
  show_plan
  confirm_generation
  generate_fstab
  validate_fstab_entries
  validate_btrfs_entries
  validate_efi_entry
  validate_mount_simulation
  show_result
}

main "$@"
