```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly DEFAULT_BTRFS_DEVICE="/dev/mapper/cryptroot"
readonly DEFAULT_MOUNT_ROOT="/mnt"
readonly DEFAULT_MOUNT_OPTIONS="noatime,compress=zstd:3"

readonly SUBVOLUME_MOUNTS=(
  "@home:/home"
  "@var:/var"
  "@var_log:/var/log"
  "@var_cache:/var/cache"
  "@pkg:/var/cache/pacman/pkg"
  "@docker:/var/lib/docker"
  "@snapshots:/.snapshots"
)

BTRFS_DEVICE="$DEFAULT_BTRFS_DEVICE"
EFI_PARTITION=""
MOUNT_ROOT="$DEFAULT_MOUNT_ROOT"
MOUNT_OPTIONS="$DEFAULT_MOUNT_OPTIONS"

declare -a MOUNTS_CREATED=()
INSTALLATION_COMPLETE=false

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

cleanup() {
  local exit_code=$?
  local index
  local target

  trap - EXIT ERR INT TERM

  if [[ "$INSTALLATION_COMPLETE" == false ]]; then
    warn "An error occurred. Unmounting filesystems mounted by this script."

    for ((index = ${#MOUNTS_CREATED[@]} - 1; index >= 0; index--)); do
      target="${MOUNTS_CREATED[$index]}"

      if mountpoint --quiet "$target"; then
        umount "$target" ||
          warn "Could not unmount: $target"
      fi
    done
  fi

  exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR
trap cleanup EXIT INT TERM

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME --efi-partition /dev/<partition> [options]

Required:
  --efi-partition <path>
      Formatted EFI System Partition.

Options:
  --btrfs-device <path>
      Btrfs mapped device.
      Default: ${DEFAULT_BTRFS_DEVICE}

  --mount-root <path>
      Installation mount root.
      Default: ${DEFAULT_MOUNT_ROOT}

  --mount-options <options>
      Shared Btrfs mount options.
      Default: ${DEFAULT_MOUNT_OPTIONS}

  --help, -h
      Show this help message.

Examples:
  sudo ./$SCRIPT_NAME --efi-partition /dev/sda1

  sudo ./$SCRIPT_NAME \\
    --btrfs-device /dev/mapper/cryptroot \\
    --efi-partition /dev/nvme0n1p1 \\
    --mount-root /mnt

This script leaves all filesystems mounted for the next installation step.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    btrfs
    findmnt
    lsblk
    mkdir
    mount
    mountpoint
    readlink
    umount
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
      --btrfs-device)
        (($# >= 2)) ||
          die "Missing value for --btrfs-device."

        BTRFS_DEVICE="$2"
        shift 2
        ;;

      --efi-partition)
        (($# >= 2)) ||
          die "Missing value for --efi-partition."

        EFI_PARTITION="$2"
        shift 2
        ;;

      --mount-root)
        (($# >= 2)) ||
          die "Missing value for --mount-root."

        MOUNT_ROOT="$2"
        shift 2
        ;;

      --mount-options)
        (($# >= 2)) ||
          die "Missing value for --mount-options."

        MOUNT_OPTIONS="$2"
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

  [[ -n "$EFI_PARTITION" ]] ||
    die "The --efi-partition argument is required."
}

canonicalize_devices() {
  BTRFS_DEVICE="$(readlink -f "$BTRFS_DEVICE")"
  EFI_PARTITION="$(readlink -f "$EFI_PARTITION")"

  [[ -b "$BTRFS_DEVICE" ]] ||
    die "Btrfs target is not a block device: $BTRFS_DEVICE"

  [[ -b "$EFI_PARTITION" ]] ||
    die "EFI target is not a block device: $EFI_PARTITION"

  [[ "$BTRFS_DEVICE" != "$EFI_PARTITION" ]] ||
    die "Btrfs and EFI devices cannot be the same device."
}

validate_mount_root() {
  [[ "$MOUNT_ROOT" == /* ]] ||
    die "Mount root must be an absolute path."

  [[ "$MOUNT_ROOT" != "/" ]] ||
    die "Refusing to use / as the installation mount root."

  if mountpoint --quiet "$MOUNT_ROOT"; then
    die "Mount root is already mounted: $MOUNT_ROOT"
  fi

  if [[ -e "$MOUNT_ROOT" && ! -d "$MOUNT_ROOT" ]]; then
    die "Mount root exists and is not a directory."
  fi

  if [[ -d "$MOUNT_ROOT" ]] &&
    [[ -n "$(
      find "$MOUNT_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -print \
        -quit
    )" ]]; then
    die "Mount root is not empty: $MOUNT_ROOT"
  fi
}

validate_btrfs_device() {
  local filesystem_type

  filesystem_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output FSTYPE \
      "$BTRFS_DEVICE" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs on $BTRFS_DEVICE, found: ${filesystem_type:-unknown}"

  if findmnt --noheadings --source "$BTRFS_DEVICE" \
    >/dev/null 2>&1; then
    die "Btrfs device is already mounted."
  fi
}

validate_efi_partition() {
  local device_type
  local filesystem_type
  local partition_type
  local expected_partition_type

  expected_partition_type="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"

  device_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output TYPE \
      "$EFI_PARTITION" |
      xargs
  )"

  filesystem_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output FSTYPE \
      "$EFI_PARTITION" |
      xargs
  )"

  partition_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output PARTTYPE \
      "$EFI_PARTITION" |
      xargs |
      tr '[:lower:]' '[:upper:]'
  )"

  [[ "$device_type" == "part" ]] ||
    die "EFI target must be a partition."

  [[ "$filesystem_type" == "vfat" ]] ||
    die "Expected FAT filesystem on EFI partition, found: ${filesystem_type:-unknown}"

  [[ "$partition_type" == "$expected_partition_type" ]] ||
    die "Target is not marked as an EFI System Partition."

  if findmnt --noheadings --source "$EFI_PARTITION" \
    >/dev/null 2>&1; then
    die "EFI partition is already mounted."
  fi
}

mount_btrfs_subvolume() {
  local subvolume=$1
  local relative_target=$2
  local target="${MOUNT_ROOT}${relative_target}"

  mkdir -p "$target"

  log "Mounting $subvolume at $target."

  mount \
    --types btrfs \
    --options "${MOUNT_OPTIONS},subvol=${subvolume}" \
    "$BTRFS_DEVICE" \
    "$target"

  MOUNTS_CREATED+=("$target")

  mountpoint --quiet "$target" ||
    die "Mountpoint was not mounted successfully: $target"
}

mount_root_subvolume() {
  mkdir -p "$MOUNT_ROOT"

  log "Mounting root subvolume @ at $MOUNT_ROOT."

  mount \
    --types btrfs \
    --options "${MOUNT_OPTIONS},subvol=@" \
    "$BTRFS_DEVICE" \
    "$MOUNT_ROOT"

  MOUNTS_CREATED+=("$MOUNT_ROOT")

  mountpoint --quiet "$MOUNT_ROOT" ||
    die "Root subvolume was not mounted successfully."
}

mount_additional_subvolumes() {
  local mapping
  local subvolume
  local relative_target

  for mapping in "${SUBVOLUME_MOUNTS[@]}"; do
    subvolume="${mapping%%:*}"
    relative_target="${mapping#*:}"

    mount_btrfs_subvolume \
      "$subvolume" \
      "$relative_target"
  done
}

mount_efi_partition() {
  local target="${MOUNT_ROOT}/boot"

  mkdir -p "$target"

  log "Mounting EFI System Partition at $target."

  mount \
    --types vfat \
    "$EFI_PARTITION" \
    "$target"

  MOUNTS_CREATED+=("$target")

  mountpoint --quiet "$target" ||
    die "EFI System Partition was not mounted successfully."
}

validate_btrfs_mount() {
  local target=$1
  local expected_subvolume=$2
  local filesystem_type
  local filesystem_root
  local mount_options

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$target" |
      xargs
  )"

  filesystem_root="$(
    findmnt \
      --noheadings \
      --output FSROOT \
      --target "$target" |
      xargs
  )"

  mount_options="$(
    findmnt \
      --noheadings \
      --output OPTIONS \
      --target "$target" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs at $target."

  [[ "$filesystem_root" == "/${expected_subvolume}" ]] ||
    die "Expected subvolume $expected_subvolume at $target."

  [[ ",$mount_options," == *",noatime,"* ]] ||
    die "Mount option noatime is missing at $target."

  [[ ",$mount_options," == *",compress=zstd:3,"* ]] ||
    die "Mount option compress=zstd:3 is missing at $target."
}

validate_efi_mount() {
  local target="${MOUNT_ROOT}/boot"
  local filesystem_type

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$target" |
      xargs
  )"

  [[ "$filesystem_type" == "vfat" ]] ||
    die "Expected vfat at $target."
}

validate_mount_tree() {
  local mapping
  local subvolume
  local relative_target

  validate_btrfs_mount "$MOUNT_ROOT" "@"

  for mapping in "${SUBVOLUME_MOUNTS[@]}"; do
    subvolume="${mapping%%:*}"
    relative_target="${mapping#*:}"

    validate_btrfs_mount \
      "${MOUNT_ROOT}${relative_target}" \
      "$subvolume"
  done

  validate_efi_mount
}

show_plan() {
  cat <<EOF

Btrfs device
------------

Device:  $BTRFS_DEVICE
Options: $MOUNT_OPTIONS

EFI System Partition
--------------------

Device:     $EFI_PARTITION
Mountpoint: ${MOUNT_ROOT}/boot

Mount tree
----------

@           -> $MOUNT_ROOT
@home       -> ${MOUNT_ROOT}/home
@var        -> ${MOUNT_ROOT}/var
@var_log    -> ${MOUNT_ROOT}/var/log
@var_cache  -> ${MOUNT_ROOT}/var/cache
@pkg        -> ${MOUNT_ROOT}/var/cache/pacman/pkg
@docker     -> ${MOUNT_ROOT}/var/lib/docker
@snapshots  -> ${MOUNT_ROOT}/.snapshots
EOF
}

confirm_mounting() {
  local confirmation

  printf '\nType MOUNT to create the installation mount tree: '
  read -r confirmation

  [[ "$confirmation" == "MOUNT" ]] ||
    die "Filesystem mounting was not authorized."
}

show_result() {
  printf '\nInstallation filesystems mounted successfully.\n\n'

  findmnt \
    --real \
    --submounts \
    "$MOUNT_ROOT"

  printf '\nNext step:\n'
  printf '  09-install-base-system\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_devices
  validate_mount_root
  validate_btrfs_device
  validate_efi_partition
  show_plan
  confirm_mounting
  mount_root_subvolume
  mount_additional_subvolumes
  mount_efi_partition
  validate_mount_tree

  INSTALLATION_COMPLETE=true

  show_result
}

main "$@"
```
