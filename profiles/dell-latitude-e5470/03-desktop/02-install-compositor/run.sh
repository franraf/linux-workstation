#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/compositor.txt"

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

Installs and validates the Hyprland compositor.

Package source:
  ${PACKAGE_FILE}
EOF
}

validate_graphics_prerequisites() {
  log_info "Validating graphics prerequisites."

  require_package_installed mesa "Run 01-install-graphics-stack first."
  require_package_installed wayland "Run 01-install-graphics-stack first."
}

show_plan() {
  printf '\nHyprland compositor installation\n'
  printf '%s\n\n' '-------------------------------'
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
  printf '\nType PACKAGES to install the missing compositor packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Compositor package installation was not authorized."
}

validate_compositor() {
  log_info "Validating Hyprland installation."

  require_commands Hyprland start-hyprland

  local package_version
  package_version="$(pacman -Q hyprland 2>/dev/null)" || die "Could not query the installed Hyprland package."
  [[ -n "$package_version" ]] || die "Hyprland package query returned empty output."

  printf '\nHyprland package:\n  %s\n' "$package_version"
  printf '\nRuntime version will be validated later from the authenticated graphical user session.\n'
}

show_result() {
  printf '\nHyprland compositor installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nNext step:\n  03-install-status-bar\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  (($# == 0)) || die "Unknown argument: $1"

  require_root
  require_commands awk grep pacman sed
  require_arch_systemd
  validate_graphics_prerequisites

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages
  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  validate_compositor
  show_result
}

main "$@"
