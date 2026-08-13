#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/file-manager.txt"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Installs and validates the Thunar file manager and its desktop integration components.

Package source:
  ${PACKAGE_FILE}
EOF
}

show_plan() {
  printf '\nThunar file manager installation\n'
  printf '%s\n\n' '--------------------------------'
  printf 'Package file:\n  %s\n\n' "$PACKAGE_FILE"
  printf 'Declared packages:\n'
  printf '  - %s\n' "${PACKAGES[@]}"

  printf '\nPackages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_installation() {
  ((${#MISSING_PACKAGES[@]} > 0)) || return

  local confirmation
  printf '\nType PACKAGES to install the missing file manager packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "File manager package installation was not authorized."
}

validate_file_manager() {
  log_info "Validating Thunar installation."

  require_commands thunar

  local version_output
  version_output="$(thunar --version 2>&1)" || die "Thunar did not return version information."
  [[ -n "$version_output" ]] || die "Thunar returned empty version information."

  printf '\nThunar version:\n'
  printf '%s\n' "$version_output" | sed 's/^/  /'

  require_package_installed gvfs "The file manager package list must provide GVfs integration."
  require_package_installed tumbler "The file manager package list must provide thumbnail support."
  require_package_installed thunar-volman "The file manager package list must provide removable-media integration."
}

show_result() {
  printf '\nThunar file manager installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nGraphical navigation, file operations, thumbnails and removable-media behavior will be validated after file-manager configuration.\n'
  printf '\nNext step:\n  10-install-font-stack\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  (($# == 0)) || die "Unknown argument: $1"

  require_root
  require_commands pacman sed
  require_arch_systemd
  require_package_installed hyprland "Run 02-install-compositor first."

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages
  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  validate_file_manager
  show_result
}

main "$@"
