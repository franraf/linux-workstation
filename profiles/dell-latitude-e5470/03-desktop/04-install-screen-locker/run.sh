#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/screen-locker.txt"

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

Installs and validates the Hyprlock screen locker.

Package source:
  ${PACKAGE_FILE}
EOF
}

show_plan() {
  printf '\nHyprlock screen locker installation\n'
  printf '%s\n\n' '----------------------------------'
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
  printf '\nType PACKAGES to install the missing screen locker packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Screen locker package installation was not authorized."
}

validate_screen_locker() {
  log_info "Validating Hyprlock installation."

  require_commands hyprlock

  local version_output
  version_output="$(hyprlock --version 2>&1)" || die "Hyprlock did not return version information."
  [[ -n "$version_output" ]] || die "Hyprlock returned empty version information."

  printf '\nHyprlock version:\n  %s\n' "$version_output"
}

show_result() {
  printf '\nHyprlock screen locker installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nInteractive lock and unlock will be validated after session-lock configuration is installed.\n'
  printf '\nNext step:\n  05-install-idle-manager\n'
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
  validate_screen_locker
  show_result
}

main "$@"
