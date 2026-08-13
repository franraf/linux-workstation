#!/usr/bin/env bash

require_uefi() {
  [[ -d /sys/firmware/efi ]] ||
    die "The installation environment was not booted in UEFI mode."
}

canonicalize_existing_path() {
  local path="${1:-}"
  [[ -n "$path" ]] || die "canonicalize_existing_path expects a path."
  [[ -e "$path" ]] || die "Path does not exist: $path"
  readlink -f "$path"
}

require_target_root_mount() {
  local target_root="${1:-}"
  [[ -n "$target_root" ]] || die "require_target_root_mount expects a target root."
  [[ -d "$target_root" ]] || die "Target root does not exist: $target_root"
  [[ "$target_root" != "/" ]] || die "Refusing to operate on the running root filesystem."
  findmnt --mountpoint "$target_root" >/dev/null 2>&1 ||
    die "Target root is not a mountpoint: $target_root"
}

require_btrfs_root_subvolume() {
  local target_root="${1:-}"
  local expected_subvolume="${2:-/@}"
  local filesystem_type
  local filesystem_root

  require_target_root_mount "$target_root"

  filesystem_type="$(findmnt --noheadings --output FSTYPE --target "$target_root" | xargs)"
  filesystem_root="$(findmnt --noheadings --output FSROOT --target "$target_root" | xargs)"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs at $target_root, found: ${filesystem_type:-unknown}"
  [[ "$filesystem_root" == "$expected_subvolume" ]] ||
    die "Expected subvolume ${expected_subvolume} at $target_root, found: ${filesystem_root:-unknown}"
}

require_arch_target_system() {
  local target_root="${1:-}"
  [[ -n "$target_root" ]] || die "require_arch_target_system expects a target root."
  [[ -f "$target_root/etc/os-release" ]] ||
    die "Target system does not contain /etc/os-release."
  grep -q '^ID=arch$' "$target_root/etc/os-release" ||
    die "Target system is not identified as Arch Linux."
}

require_mountpoints() {
  local target_root="${1:-}"
  shift || true
  (($# > 0)) || die "require_mountpoints expects at least one relative mountpoint."

  local relative_mountpoint
  local absolute_mountpoint

  for relative_mountpoint in "$@"; do
    if [[ "$relative_mountpoint" == "/" ]]; then
      absolute_mountpoint="$target_root"
    else
      absolute_mountpoint="${target_root}${relative_mountpoint}"
    fi

    findmnt --mountpoint "$absolute_mountpoint" >/dev/null 2>&1 ||
      die "Required mountpoint is missing: $absolute_mountpoint"
  done
}

require_filesystem_type() {
  local mountpoint_path="${1:-}"
  local expected_type="${2:-}"
  local actual_type

  [[ -n "$mountpoint_path" && -n "$expected_type" ]] ||
    die "require_filesystem_type expects a mountpoint and filesystem type."

  actual_type="$(findmnt --noheadings --output FSTYPE --target "$mountpoint_path" | xargs)"
  [[ "$actual_type" == "$expected_type" ]] ||
    die "Expected ${expected_type} at ${mountpoint_path}, found: ${actual_type:-unknown}"
}
