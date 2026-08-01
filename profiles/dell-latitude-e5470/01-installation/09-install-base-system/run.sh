#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

readonly DEFAULT_ROOT="/mnt"
readonly DEFAULT_PACKAGE_FILE="${SCRIPT_DIRECTORY}/packages.txt"

TARGET_ROOT="$DEFAULT_ROOT"
PACKAGE_FILE="$DEFAULT_PACKAGE_FILE"

declare -a PACKAGES=()

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
  sudo ./$SCRIPT_NAME [options]

Options:
  --root <path>
      Mounted target root.
      Default: ${DEFAULT_ROOT}

  --package-file <path>
      File containing one package per line.
      Default: ${DEFAULT_PACKAGE_FILE}

  --help, -h
      Show this help message.

Examples:
  sudo ./$SCRIPT_NAME

  sudo ./$SCRIPT_NAME \\
    --root /mnt \\
    --package-file ./packages.txt

The package file supports:

  - one package per line;
  - empty lines;
  - comments beginning with #.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    arch-chroot
    awk
    findmnt
    lsblk
    pacstrap
    readlink
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
      --root)
        (($# >= 2)) ||
          die "Missing value for --root."

        TARGET_ROOT="$2"
        shift 2
        ;;

      --package-file)
        (($# >= 2)) ||
          die "Missing value for --package-file."

        PACKAGE_FILE="$2"
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
}

canonicalize_paths() {
  if [[ -e "$TARGET_ROOT" ]]; then
    TARGET_ROOT="$(readlink -f "$TARGET_ROOT")"
  fi

  PACKAGE_FILE="$(readlink -f "$PACKAGE_FILE")"
}

validate_target_root() {
  [[ -d "$TARGET_ROOT" ]] ||
    die "Target root does not exist: $TARGET_ROOT"

  [[ "$TARGET_ROOT" != "/" ]] ||
    die "Refusing to install the system into the running root filesystem."

  findmnt --mountpoint "$TARGET_ROOT" >/dev/null 2>&1 ||
    die "Target root is not a mountpoint: $TARGET_ROOT"

  local filesystem_type
  local filesystem_root

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$TARGET_ROOT" |
      xargs
  )"

  filesystem_root="$(
    findmnt \
      --noheadings \
      --output FSROOT \
      --target "$TARGET_ROOT" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs at $TARGET_ROOT, found: $filesystem_type"

  [[ "$filesystem_root" == "/@" ]] ||
    die "Expected the @ subvolume at $TARGET_ROOT."
}

validate_mount_tree() {
  local required_mountpoints=(
    "$TARGET_ROOT"
    "$TARGET_ROOT/boot"
    "$TARGET_ROOT/home"
    "$TARGET_ROOT/var"
    "$TARGET_ROOT/var/log"
    "$TARGET_ROOT/var/cache"
    "$TARGET_ROOT/var/cache/pacman/pkg"
    "$TARGET_ROOT/var/lib/docker"
    "$TARGET_ROOT/.snapshots"
  )

  local mountpoint_path

  for mountpoint_path in "${required_mountpoints[@]}"; do
    findmnt --mountpoint "$mountpoint_path" >/dev/null 2>&1 ||
      die "Required mountpoint is missing: $mountpoint_path"
  done
}

validate_efi_mount() {
  local efi_mount="${TARGET_ROOT}/boot"
  local filesystem_type

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$efi_mount" |
      xargs
  )"

  [[ "$filesystem_type" == "vfat" ]] ||
    die "Expected vfat at $efi_mount, found: $filesystem_type"
}

validate_package_file() {
  [[ -f "$PACKAGE_FILE" ]] ||
    die "Package file does not exist: $PACKAGE_FILE"

  [[ -r "$PACKAGE_FILE" ]] ||
    die "Package file is not readable: $PACKAGE_FILE"
}

load_packages() {
  mapfile -t PACKAGES < <(
    awk '
      {
        sub(/[[:space:]]*#.*/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      }

      length($0) > 0 {
        print
      }
    ' "$PACKAGE_FILE"
  )

  ((${#PACKAGES[@]} > 0)) ||
    die "Package file does not contain any packages."
}

validate_package_names() {
  local package

  for package in "${PACKAGES[@]}"; do
    [[ "$package" =~ ^[a-zA-Z0-9@._+-]+$ ]] ||
      die "Invalid package name in package file: $package"
  done
}

validate_required_packages() {
  local required_packages=(
    base
    linux
    linux-firmware
    intel-ucode
    btrfs-progs
    cryptsetup
    networkmanager
    sudo
  )

  local required_package

  for required_package in "${required_packages[@]}"; do
    if ! printf '%s\n' "${PACKAGES[@]}" |
      grep -Fxq "$required_package"; then
      die "Required package is missing from package file: $required_package"
    fi
  done
}

validate_target_is_empty() {
  local existing_system_paths=(
    "$TARGET_ROOT/etc/os-release"
    "$TARGET_ROOT/usr/bin/pacman"
    "$TARGET_ROOT/var/lib/pacman/local"
  )

  local path

  for path in "${existing_system_paths[@]}"; do
    if [[ -e "$path" ]]; then
      die "Target already appears to contain an installed system: $path"
    fi
  done
}

show_plan() {
  cat <<EOF

Installation target
-------------------

Root:         $TARGET_ROOT
Package file: $PACKAGE_FILE

Packages
--------

EOF

  printf '  - %s\n' "${PACKAGES[@]}"

  cat <<EOF

The packages and their dependencies will be installed into:

  $TARGET_ROOT
EOF
}

confirm_installation() {
  local confirmation

  printf '\nType INSTALL to begin the base system installation: '
  read -r confirmation

  [[ "$confirmation" == "INSTALL" ]] ||
    die "Base system installation was not authorized."
}

install_base_system() {
  log "Installing ${#PACKAGES[@]} declared packages."

  pacstrap \
    -K \
    "$TARGET_ROOT" \
    "${PACKAGES[@]}"
}

validate_installed_system() {
  local required_paths=(
    "$TARGET_ROOT/etc"
    "$TARGET_ROOT/usr/bin/bash"
    "$TARGET_ROOT/usr/bin/pacman"
    "$TARGET_ROOT/usr/bin/systemctl"
    "$TARGET_ROOT/usr/bin/cryptsetup"
    "$TARGET_ROOT/usr/bin/btrfs"
    "$TARGET_ROOT/usr/lib/modules"
    "$TARGET_ROOT/boot"
    "$TARGET_ROOT/var/lib/pacman/local"
  )

  local path

  for path in "${required_paths[@]}"; do
    [[ -e "$path" ]] ||
      die "Expected installed-system path is missing: $path"
  done

  [[ -f "$TARGET_ROOT/etc/os-release" ]] ||
    die "Target system does not contain /etc/os-release."

  grep -q '^ID=arch$' "$TARGET_ROOT/etc/os-release" ||
    die "Target system is not identified as Arch Linux."
}

validate_installed_packages() {
  local package

  for package in "${PACKAGES[@]}"; do
    arch-chroot "$TARGET_ROOT" \
      pacman -Q "$package" >/dev/null 2>&1 ||
      die "Package was not installed correctly: $package"
  done
}

show_result() {
  printf '\nBase system installed successfully.\n\n'

  printf 'Installed packages declared by the profile:\n\n'

  arch-chroot "$TARGET_ROOT" \
    pacman -Q "${PACKAGES[@]}"

  printf '\nKernel files:\n\n'

  find "$TARGET_ROOT/boot" \
    -mindepth 1 \
    -maxdepth 1 \
    -printf '  %f\n' |
    sort

  printf '\nNext step:\n'
  printf '  10-generate-fstab\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_paths
  validate_target_root
  validate_mount_tree
  validate_efi_mount
  validate_package_file
  load_packages
  validate_package_names
  validate_required_packages
  validate_target_is_empty
  show_plan
  confirm_installation
  install_base_system
  validate_installed_system
  validate_installed_packages
  show_result
}

main "$@"
