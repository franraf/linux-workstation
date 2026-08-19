#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_ROOT="/mnt"
readonly DEFAULT_PACKAGE_FILE="${REPO_ROOT}/packages/installation/base-system-intel.txt"

TARGET_ROOT="$DEFAULT_ROOT"
PACKAGE_FILE="$DEFAULT_PACKAGE_FILE"

declare -a PACKAGES=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [options]

Options:
  --root <path>
      Mounted target root.
      Default: ${DEFAULT_ROOT}

  --package-file <path>
      Declarative package source.
      Default: ${DEFAULT_PACKAGE_FILE}

  --help, -h
      Show this help message.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --root)
        (($# >= 2)) || die "Missing value for --root."
        TARGET_ROOT="$2"
        shift 2
        ;;
      --package-file)
        (($# >= 2)) || die "Missing value for --package-file."
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
  TARGET_ROOT="$(canonicalize_existing_path "$TARGET_ROOT")"
  PACKAGE_FILE="$(canonicalize_existing_path "$PACKAGE_FILE")"
}

validate_mount_tree() {
  require_btrfs_root_subvolume "$TARGET_ROOT" "/@"
  require_mountpoints "$TARGET_ROOT" \
    / /boot /home /var /var/log /var/cache /var/cache/pacman/pkg /var/lib/docker /.snapshots
  require_filesystem_type "$TARGET_ROOT/boot" vfat
}

package_declared() {
  local expected="$1"
  local package
  for package in "${PACKAGES[@]}"; do
    [[ "$package" == "$expected" ]] && return 0
  done
  return 1
}

validate_required_packages() {
  local required_packages=(
    base linux linux-firmware intel-ucode btrfs-progs cryptsetup networkmanager sudo
  )
  local required_package

  for required_package in "${required_packages[@]}"; do
    package_declared "$required_package" ||
      die "Required package is missing from package file: $required_package"
  done
}

validate_target_is_empty() {
  local path
  for path in \
    "$TARGET_ROOT/etc/os-release" \
    "$TARGET_ROOT/usr/bin/pacman" \
    "$TARGET_ROOT/var/lib/pacman/local"; do
    [[ ! -e "$path" ]] || die "Target already appears to contain an installed system: $path"
  done
}

show_plan() {
  printf '\nBase system installation\n'
  printf '%s\n\n' '------------------------'
  printf 'Target root:\n  %s\n\n' "$TARGET_ROOT"
  printf 'Package source:\n  %s\n\n' "$PACKAGE_FILE"
  printf 'Declared packages:\n'
  printf '  - %s\n' "${PACKAGES[@]}"
}

confirm_installation() {
  local confirmation
  printf '\nType INSTALL to begin the base system installation: '
  read -r confirmation
  [[ "$confirmation" == "INSTALL" ]] || die "Base system installation was not authorized."
}

install_base_system() {
  log_info "Installing ${#PACKAGES[@]} declared packages into ${TARGET_ROOT}."
  pacstrap -K "$TARGET_ROOT" "${PACKAGES[@]}"
}

validate_installed_system() {
  local path
  for path in \
    "$TARGET_ROOT/usr/bin/bash" \
    "$TARGET_ROOT/usr/bin/pacman" \
    "$TARGET_ROOT/usr/bin/systemctl" \
    "$TARGET_ROOT/usr/bin/cryptsetup" \
    "$TARGET_ROOT/usr/bin/btrfs" \
    "$TARGET_ROOT/usr/lib/modules" \
    "$TARGET_ROOT/var/lib/pacman/local"; do
    [[ -e "$path" ]] || die "Expected installed-system path is missing: $path"
  done

  require_arch_target_system "$TARGET_ROOT"
}

validate_target_packages() {
  local package
  for package in "${PACKAGES[@]}"; do
    arch-chroot "$TARGET_ROOT" pacman -Q "$package" >/dev/null 2>&1 ||
      die "Package was not installed correctly: $package"
  done
}

show_result() {
  printf '\nBase system installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  arch-chroot "$TARGET_ROOT" pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nNext step:\n  10-generate-fstab\n'
}

main() {
  require_root
  require_commands arch-chroot awk findmnt pacman pacstrap readlink sed xargs
  parse_arguments "$@"
  canonicalize_paths
  validate_mount_tree
  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  validate_required_packages
  validate_target_is_empty
  show_plan
  confirm_installation
  install_base_system
  validate_installed_system
  validate_target_packages
  show_result
}

main "$@"
