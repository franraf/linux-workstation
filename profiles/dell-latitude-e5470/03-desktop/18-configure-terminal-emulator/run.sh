#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly KITTY_SOURCE_DIRECTORY="${REPO_ROOT}/system/kitty"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/system/hyprland/modules/70-keybindings.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Kitty configuration and canonical Hyprland terminal binding.
EOF
}

resolve_user_home() {
  getent passwd "$1" | cut -d: -f6
}

validate_user() {
  local username="$1"
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
  [[ "$username" != "root" ]] || die "Kitty configuration must target a normal user."
}

install_configuration() {
  local username="$1"
  local user_home="$2"
  local kitty_directory="${user_home}/.config/kitty"
  local hypr_directory="${user_home}/.config/hypr"

  log_info "Installing Kitty configuration for ${username}."

  install -d -m 0755 -o "$username" -g "$username" "$kitty_directory" "$hypr_directory" "$hypr_directory/modules"
  install -m 0644 -o "$username" -g "$username" "${KITTY_SOURCE_DIRECTORY}/kitty.conf" "$kitty_directory/kitty.conf"
  install -m 0644 -o "$username" -g "$username" "${KITTY_SOURCE_DIRECTORY}/behavior.conf" "$kitty_directory/behavior.conf"
  install -m 0644 -o "$username" -g "$username" "${KITTY_SOURCE_DIRECTORY}/keybindings.conf" "$kitty_directory/keybindings.conf"
  install -m 0644 -o "$username" -g "$username" "$KEYBINDINGS_SOURCE" "$hypr_directory/modules/70-keybindings.lua"
}

validate_configuration() {
  local user_home="$1"
  local kitty_directory="${user_home}/.config/kitty"
  local keybindings="${user_home}/.config/hypr/modules/70-keybindings.lua"

  [[ -s "$kitty_directory/kitty.conf" ]] || die "Kitty configuration was not installed."
  [[ -s "$kitty_directory/behavior.conf" ]] || die "Kitty behavior configuration was not installed."
  [[ -s "$kitty_directory/keybindings.conf" ]] || die "Kitty internal keybindings were not installed."
  [[ -s "$keybindings" ]] || die "Hyprland keybindings module was not installed."

  grep -q '^include behavior.conf$' "$kitty_directory/kitty.conf" || die "Kitty behavior module is not included."
  grep -q '^include keybindings.conf$' "$kitty_directory/kitty.conf" || die "Kitty keybindings module is not included."
  grep -q '^font_family JetBrainsMono Nerd Font$' "$kitty_directory/behavior.conf" || die "Expected Kitty font is not configured."
  grep -q 'hl.bind("SUPER", "RETURN"' "$keybindings" || die "SUPER+RETURN terminal binding is missing."
  grep -q '"kitty"' "$keybindings" || die "Terminal binding does not invoke Kitty."
}

show_result() {
  local username="$1"
  local user_home="$2"

  printf '\nKitty terminal emulator configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$username"
  printf 'Configuration:\n  %s/.config/kitty\n\n' "$user_home"
  printf 'Binding:\n  SUPER + RETURN -> kitty\n\n'
  printf 'Visual theme remains the responsibility of 20-configure-appearance.\n'
  printf 'Graphical startup, clipboard and Unicode rendering must be validated from the Hyprland session.\n'
  printf '\nNext step:\n  19-configure-file-manager\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  (($# == 1)) || die "Expected exactly one argument: username"

  local username="$1"
  local user_home

  require_root
  require_commands cut getent grep id install
  require_arch_systemd
  require_package_installed kitty "Run 08-install-terminal-emulator first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_user "$username"
  user_home="$(resolve_user_home "$username")"
  [[ -n "$user_home" && -d "$user_home" ]] || die "Could not resolve a valid home directory for ${username}."

  local source_file
  for source_file in kitty.conf behavior.conf keybindings.conf; do
    [[ -s "${KITTY_SOURCE_DIRECTORY}/${source_file}" ]] || die "Shared Kitty file is missing: ${source_file}"
  done
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  install_configuration "$username" "$user_home"
  validate_configuration "$user_home"
  show_result "$username" "$user_home"
}

main "$@"
