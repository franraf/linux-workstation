#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly HYPRLOCK_SOURCE="${REPO_ROOT}/system/hyprlock/hyprlock.conf"
readonly HYPRLAND_SOURCE="${REPO_ROOT}/system/hyprland/modules/60-session-lock.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Hyprlock configuration and canonical Hyprland session-lock module.
EOF
}

install_configuration() {
  local hypr_directory
  hypr_directory="$(user_config_path hypr)"

  log_info "Installing Hyprlock configuration for ${TARGET_USER}."
  install_user_directory "$hypr_directory"
  install_user_directory "${hypr_directory}/modules"
  install_user_file "$HYPRLOCK_SOURCE" "${hypr_directory}/hyprlock.conf"
  install_user_file "$HYPRLAND_SOURCE" "${hypr_directory}/modules/60-session-lock.lua"
}

validate_configuration() {
  local hypr_directory
  hypr_directory="$(user_config_path hypr)"

  [[ -s "$hypr_directory/hyprlock.conf" ]] || die "Hyprlock configuration was not installed."
  [[ -s "$hypr_directory/modules/60-session-lock.lua" ]] || die "Session-lock module was not installed."
  grep -Fq 'hl.bind("SUPER + L", hl.dsp.exec_cmd(' "$hypr_directory/modules/60-session-lock.lua" || die "SUPER+L binding is missing."
  grep -q 'hyprlock' "$hypr_directory/modules/60-session-lock.lua" || die "Session-lock binding does not invoke Hyprlock."
}

show_result() {
  printf '\nSession lock configuration installed successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Hyprlock configuration:\n  %s\n\n' "$(user_config_path hypr/hyprlock.conf)"
  printf 'Binding:\n  SUPER + L -> Hyprlock\n\n'
  printf 'Interactive authentication must be validated from the graphical session.\n'
  printf '\nNext step:\n  15-configure-session-lifecycle\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands grep
  require_user_config_commands
  require_arch_systemd
  require_package_installed hyprlock "Run 04-install-screen-locker first."
  require_package_installed hyprland "Run 02-install-compositor first."
  resolve_normal_user "$1"

  [[ -s "$HYPRLOCK_SOURCE" ]] || die "Shared Hyprlock configuration is missing."
  [[ -s "$HYPRLAND_SOURCE" ]] || die "Shared session-lock module is missing."

  install_configuration
  validate_configuration
  show_result
}

main "$@"
