#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/application-launcher.txt"

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

Installs and validates the Rofi application launcher.

Package source:
  ${PACKAGE_FILE}
EOF
}

show_plan() {
  printf '\nRofi application launcher installation\n'
  printf '%s\n\n' '-------------------------------------'
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
  printf '\nType PACKAGES to install the missing application launcher packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Application launcher package installation was not authorized."
}

validate_application_launcher() {
  log_info "Validating Rofi installation."

  require_commands rofi

  local version_output
  version_output="$(rofi -version 2>&1)" || die "Rofi did not return version information."
  [[ -n "$version_output" ]] || die "Rofi returned empty version information."

  printf '\nRofi version:\n  %s\n' "$version_output"
}

show_result() {
  printf '\nRofi application launcher installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nLauncher behavior, keybindings and application discovery will be validated after configuration.\n'
  printf '\nNext step:\n  07-install-notification-center\n'
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
  validate_application_launcher
  show_result
}

main "$@"
