#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly HYPRIDLE_SOURCE="${REPO_ROOT}/system/hypridle/hypridle.conf"
readonly AUTOSTART_SOURCE="${REPO_ROOT}/system/hyprland/modules/50-autostart.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Hypridle lifecycle policy and canonical Hyprland autostart registry.
EOF
}

install_configuration() {
  local hypr_directory
  hypr_directory="$(user_config_path hypr)"

  log_info "Installing Hypridle lifecycle configuration for ${TARGET_USER}."
  install_user_directory "$hypr_directory"
  install_user_directory "${hypr_directory}/modules"
  install_user_file "$HYPRIDLE_SOURCE" "${hypr_directory}/hypridle.conf"
  install_user_file "$AUTOSTART_SOURCE" "${hypr_directory}/modules/50-autostart.lua"
}

validate_configuration() {
  local hypr_directory
  hypr_directory="$(user_config_path hypr)"

  [[ -s "$hypr_directory/hypridle.conf" ]] || die "Hypridle configuration was not installed."
  [[ -s "$hypr_directory/modules/50-autostart.lua" ]] || die "Hyprland autostart module was not installed."
  grep -q 'lock_cmd = pidof hyprlock || hyprlock' "$hypr_directory/hypridle.conf" || die "Hypridle lock command is missing."
  grep -q 'timeout = 300' "$hypr_directory/hypridle.conf" || die "Automatic lock timeout is missing."
  grep -q 'timeout = 600' "$hypr_directory/hypridle.conf" || die "Display power timeout is missing."
  grep -q 'timeout = 1800' "$hypr_directory/hypridle.conf" || die "Suspend timeout is missing."
  [[ "$(grep -c 'pidof hypridle || hypridle' "$hypr_directory/modules/50-autostart.lua")" -eq 1 ]] || die "Hypridle must appear exactly once in autostart."
}

show_result() {
  printf '\nSession lifecycle configuration installed successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Policy:\n  5 min -> lock\n  10 min -> display off\n  30 min -> suspend\n\n'
  printf 'Runtime behavior must be validated from the graphical session.\n'
  printf '\nNext step:\n  16-configure-application-launcher\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands grep
  require_user_config_commands
  require_arch_systemd
  require_package_installed hypridle "Run 05-install-idle-manager first."
  require_package_installed hyprlock "Run 04-install-screen-locker first."
  require_package_installed hyprland "Run 02-install-compositor first."
  resolve_normal_user "$1"

  [[ -s "$HYPRIDLE_SOURCE" ]] || die "Shared Hypridle configuration is missing."
  [[ -s "$AUTOSTART_SOURCE" ]] || die "Shared Hyprland autostart module is missing."

  install_configuration
  validate_configuration
  show_result
}

main "$@"
