#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly KITTY_SOURCE_DIRECTORY="${REPO_ROOT}/system/kitty"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/system/hyprland/modules/70-keybindings.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Kitty configuration and canonical Hyprland terminal binding.
EOF
}

install_configuration() {
  local kitty_directory hypr_directory
  kitty_directory="$(user_config_path kitty)"
  hypr_directory="$(user_config_path hypr)"

  log_info "Installing Kitty configuration for ${TARGET_USER}."
  install_user_directory "$kitty_directory"
  install_user_directory "$hypr_directory"
  install_user_directory "${hypr_directory}/modules"
  install_user_file "${KITTY_SOURCE_DIRECTORY}/kitty.conf" "${kitty_directory}/kitty.conf"
  install_user_file "${KITTY_SOURCE_DIRECTORY}/behavior.conf" "${kitty_directory}/behavior.conf"
  install_user_file "${KITTY_SOURCE_DIRECTORY}/keybindings.conf" "${kitty_directory}/keybindings.conf"
  install_user_file "$KEYBINDINGS_SOURCE" "${hypr_directory}/modules/70-keybindings.lua"
}

validate_configuration() {
  local kitty_directory keybindings
  kitty_directory="$(user_config_path kitty)"
  keybindings="$(user_config_path hypr/modules/70-keybindings.lua)"

  [[ -s "$kitty_directory/kitty.conf" ]] || die "Kitty configuration was not installed."
  [[ -s "$kitty_directory/behavior.conf" ]] || die "Kitty behavior configuration was not installed."
  [[ -s "$kitty_directory/keybindings.conf" ]] || die "Kitty internal keybindings were not installed."
  [[ -s "$keybindings" ]] || die "Hyprland keybindings module was not installed."
  grep -q '^include behavior.conf$' "$kitty_directory/kitty.conf" || die "Kitty behavior module is not included."
  grep -q '^include keybindings.conf$' "$kitty_directory/kitty.conf" || die "Kitty keybindings module is not included."
  grep -q '^font_family JetBrainsMono Nerd Font$' "$kitty_directory/behavior.conf" || die "Expected Kitty font is not configured."
  grep -Fq 'hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))' "$keybindings" || die "SUPER+RETURN terminal binding is missing."
}

show_result() {
  printf '\nKitty terminal emulator configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Configuration:\n  %s\n\n' "$(user_config_path kitty)"
  printf 'Binding:\n  SUPER + RETURN -> kitty\n\n'
  printf 'Visual theme remains the responsibility of 20-configure-appearance.\n'
  printf '\nNext step:\n  19-configure-file-manager\n'
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
  require_package_installed kitty "Run 08-install-terminal-emulator first."
  require_package_installed hyprland "Run 02-install-compositor first."
  resolve_normal_user "$1"

  local source_file
  for source_file in kitty.conf behavior.conf keybindings.conf; do
    [[ -s "${KITTY_SOURCE_DIRECTORY}/${source_file}" ]] || die "Shared Kitty file is missing: ${source_file}"
  done
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  install_configuration
  validate_configuration
  show_result
}

main "$@"
