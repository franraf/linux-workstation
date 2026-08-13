#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/terminal-emulator.txt"

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

Installs and validates the Kitty terminal emulator.

Package source:
  ${PACKAGE_FILE}
EOF
}

show_plan() {
  printf '\nKitty terminal emulator installation\n'
  printf '%s\n\n' '-----------------------------------'
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
  printf '\nType PACKAGES to install the missing terminal emulator packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Terminal emulator package installation was not authorized."
}

validate_terminal_emulator() {
  log_info "Validating Kitty installation."

  require_commands kitty

  local version_output
  version_output="$(kitty --version 2>&1)" || die "Kitty did not return version information."
  [[ -n "$version_output" ]] || die "Kitty returned empty version information."

  printf '\nKitty version:\n  %s\n' "$version_output"
}

show_result() {
  printf '\nKitty terminal emulator installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nGraphical startup, shell integration and Unicode rendering will be validated after terminal configuration and font installation.\n'
  printf '\nNext step:\n  09-install-file-manager\n'
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
  validate_terminal_emulator
  show_result
}

main "$@"
