#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/compositor.txt"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"

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

require_root() {
  [[ $EUID -eq 0 ]] || die "This script must be executed as root."
}

require_commands() {
  local commands=(awk grep pacman sed)
  local command_name

  for command_name in "${commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || die "Required command not found: $command_name"
  done
}

validate_execution_context() {
  [[ -f /etc/os-release ]] || die "The current root does not contain /etc/os-release."
  grep -q '^ID=arch$' /etc/os-release || die "This script must run on Arch Linux."
  [[ -d /run/systemd/system ]] || die "systemd is not running as PID 1."
}

validate_graphics_prerequisites() {
  log_info "Validating graphics prerequisites."

  pacman -Q mesa >/dev/null 2>&1 || die "Mesa is not installed. Run 01-install-graphics-stack first."
  pacman -Q wayland >/dev/null 2>&1 || die "Wayland is not installed. Run 01-install-graphics-stack first."
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
  ((${#MISSING_PACKAGES[@]} > 0)) || return

  local confirmation
  printf '\nType PACKAGES to install the missing compositor packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Compositor package installation was not authorized."
}

validate_compositor() {
  log_info "Validating Hyprland installation."

  command -v Hyprland >/dev/null 2>&1 || die "Hyprland executable was not found after installation."
  command -v start-hyprland >/dev/null 2>&1 || die "start-hyprland executable was not found after installation."

  local version_output
  version_output="$(Hyprland --version 2>&1)" || die "Hyprland did not return version information."

  [[ -n "$version_output" ]] || die "Hyprland returned empty version information."

  printf '\nHyprland version:\n'
  printf '%s\n' "$version_output" | sed 's/^/  /'
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
  require_commands
  validate_execution_context
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
