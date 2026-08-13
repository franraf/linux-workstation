#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/idle-manager.txt"

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

Installs and validates the Hypridle idle manager.

Package source:
  ${PACKAGE_FILE}
EOF
}

show_plan() {
  printf '\nHypridle idle manager installation\n'
  printf '%s\n\n' '---------------------------------'
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
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    return 0
  fi

  local confirmation
  printf '\nType PACKAGES to install the missing idle manager packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Idle manager package installation was not authorized."
}

validate_idle_manager() {
  log_info "Validating Hypridle installation."

  require_commands hypridle

  local help_output
  help_output="$(hypridle --help 2>&1)" || die "Hypridle did not respond to --help."
  [[ -n "$help_output" ]] || die "Hypridle returned empty help information."
}

show_result() {
  printf '\nHypridle idle manager installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nFunctional startup will be validated after session-lifecycle configuration is installed.\n'
  printf '\nNext step:\n  06-install-application-launcher\n'
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
  require_package_installed hyprlock "Run 04-install-screen-locker first."

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages
  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  validate_idle_manager
  show_result
}

main "$@"
