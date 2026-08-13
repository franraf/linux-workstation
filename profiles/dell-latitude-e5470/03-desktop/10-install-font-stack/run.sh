#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/font-stack.txt"

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

Installs and validates the workstation font stack.

Package source:
  ${PACKAGE_FILE}
EOF
}

show_plan() {
  printf '\nWorkstation font stack installation\n'
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
  printf '\nType PACKAGES to install the missing font packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Font package installation was not authorized."
}

rebuild_font_cache() {
  log_info "Rebuilding font cache."
  fc-cache -f >/dev/null || die "Failed to rebuild the font cache."
}

require_font_pattern() {
  local pattern="$1"
  local description="$2"

  fc-match "$pattern" 2>/dev/null | grep -qi -- "$pattern" || \
    die "Expected font was not resolved: ${description} (${pattern})."
}

validate_font_stack() {
  log_info "Validating font stack."

  require_commands fc-cache fc-list fc-match grep

  fc-list | grep -qi 'DejaVu' || die "DejaVu fonts were not found by Fontconfig."
  fc-list | grep -qi 'Noto Sans' || die "Noto Sans fonts were not found by Fontconfig."
  fc-list | grep -qi 'Noto Color Emoji' || die "Noto Color Emoji was not found by Fontconfig."
  fc-list | grep -qi 'JetBrainsMono Nerd Font' || die "JetBrainsMono Nerd Font was not found by Fontconfig."

  fc-match sans-serif >/dev/null 2>&1 || die "Fontconfig could not resolve sans-serif."
  fc-match monospace >/dev/null 2>&1 || die "Fontconfig could not resolve monospace."
  fc-match emoji >/dev/null 2>&1 || die "Fontconfig could not resolve emoji."
}

show_result() {
  printf '\nWorkstation font stack installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'

  printf '\nResolved generic fonts:\n'
  printf '  sans-serif: %s\n' "$(fc-match -f '%{family}\n' sans-serif | head -n 1)"
  printf '  monospace:  %s\n' "$(fc-match -f '%{family}\n' monospace | head -n 1)"
  printf '  emoji:      %s\n' "$(fc-match -f '%{family}\n' emoji | head -n 1)"

  printf '\nVisual rendering will be validated after desktop configuration is complete.\n'
  printf '\nNext step:\n  11-install-session-login\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  (($# == 0)) || die "Unknown argument: $1"

  require_root
  require_commands pacman sed fc-cache fc-list fc-match grep head
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
  rebuild_font_cache
  validate_font_stack
  show_result
}

main "$@"
