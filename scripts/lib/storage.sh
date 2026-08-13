#!/usr/bin/env bash

load_btrfs_layout() {
  local layout_file="${1:-}"
  [[ -n "$layout_file" ]] || die "load_btrfs_layout expects a file path."
  [[ -f "$layout_file" && -r "$layout_file" ]] || die "Btrfs layout is not readable: $layout_file"

  BTRFS_SUBVOLUMES=()
  BTRFS_MOUNTPOINTS=()

  local subvolume
  local mountpoint
  while IFS=$'\t' read -r subvolume mountpoint; do
    [[ -n "$subvolume" ]] || continue
    [[ "$subvolume" == \#* ]] && continue
    [[ -n "$mountpoint" ]] || die "Missing mountpoint for Btrfs subvolume: $subvolume"
    [[ "$subvolume" =~ ^@[a-zA-Z0-9_-]*$ ]] || die "Invalid Btrfs subvolume name: $subvolume"
    [[ "$mountpoint" == /* ]] || die "Btrfs mountpoint must be absolute: $mountpoint"

    BTRFS_SUBVOLUMES+=("$subvolume")
    BTRFS_MOUNTPOINTS+=("$mountpoint")
  done <"$layout_file"

  ((${#BTRFS_SUBVOLUMES[@]} > 0)) || die "Btrfs layout does not contain entries: $layout_file"
  ((${#BTRFS_SUBVOLUMES[@]} == ${#BTRFS_MOUNTPOINTS[@]})) || die "Invalid Btrfs layout."

  local root_count=0
  local index
  for ((index = 0; index < ${#BTRFS_SUBVOLUMES[@]}; index++)); do
    [[ "${BTRFS_MOUNTPOINTS[$index]}" == "/" ]] && ((root_count += 1))
  done
  ((root_count == 1)) || die "Btrfs layout must contain exactly one root mountpoint."
}

btrfs_layout_subvolume_for_mountpoint() {
  local expected_mountpoint="${1:-}"
  local index
  for ((index = 0; index < ${#BTRFS_SUBVOLUMES[@]}; index++)); do
    if [[ "${BTRFS_MOUNTPOINTS[$index]}" == "$expected_mountpoint" ]]; then
      printf '%s\n' "${BTRFS_SUBVOLUMES[$index]}"
      return 0
    fi
  done
  return 1
}
