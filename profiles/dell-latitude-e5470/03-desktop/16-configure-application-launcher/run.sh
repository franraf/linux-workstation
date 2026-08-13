#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly ROFI_SOURCE="${REPO_ROOT}/system/rofi/config.rasi"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/system/hyprland/modules/70-keybindings.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Rofi configuration and canonical Hyprland launcher binding.
EOF
}

install_configuration() {
  local rofi_directory hypr_directory
  rofi_directory="$(user_config_path rofi)"
  hypr_directory="$(user_config_path hypr)"

  log_info "Installing Rofi configuration for ${TARGET_USER}."
  install_user_directory "$rofi_directory"
  install_user_directory "$hypr_directory"
  install_user_directory "${hypr_directory}/modules"
  install_user_file "$ROFI_SOURCE" "${rofi_directory}/config.rasi"
  install_user_file "$KEYBINDINGS_SOURCE" "${hypr_directory}/modules/70-keybindings.lua"
}

validate_configuration() {
  local rofi_config keybindings
  rofi_config="$(user_config_path rofi/config.rasi)"
  keybindings="$(user_config_path hypr/modules/70-keybindings.lua)"

  [[ -s "$rofi_config" ]] || die "Rofi configuration was not installed."
  [[ -s "$keybindings" ]] || die "Hyprland keybindings module was not installed."
  grep -q 'modi: "drun,run"' "$rofi_config" || die "Rofi drun/run modes are not configured."
  grep -Fq 'hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun"))' "$keybindings" || die "SUPER+SPACE launcher binding is missing."

  if grep -Eq 'kb-row-(left|right)[[:space:]]*:' "$rofi_config"; then
    die "Rofi row navigation bindings must not be overridden by the shared configuration."
  fi
}

validate_effective_bindings() {
  local binding_output
  log_info "Checking Rofi built-in navigation bindings."
  binding_output="$(runuser -u "$TARGET_USER" -- rofi -list-keybindings 2>/dev/null)" || die "Could not query Rofi keybindings."
  grep -q 'kb-row-left' <<<"$binding_output" || die "Rofi kb-row-left binding is unavailable."
  grep -q 'kb-row-right' <<<"$binding_output" || die "Rofi kb-row-right binding is unavailable."
}

show_result() {
  printf '\nRofi application launcher configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Modes:\n  drun, run\n\n'
  printf 'Binding:\n  SUPER + SPACE -> rofi -show drun\n\n'
  printf 'Built-in row navigation bindings were preserved.\n'
  printf '\nNext step:\n  17-configure-notification-center\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands grep runuser
  require_user_config_commands
  require_arch_systemd
  require_package_installed rofi "Run 06-install-application-launcher first."
  require_package_installed hyprland "Run 02-install-compositor first."
  resolve_normal_user "$1"

  [[ -s "$ROFI_SOURCE" ]] || die "Shared Rofi configuration is missing."
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  install_configuration
  validate_configuration
  validate_effective_bindings
  show_result
}

main "$@"
