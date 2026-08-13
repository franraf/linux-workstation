#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly ROFI_SOURCE="${REPO_ROOT}/system/rofi/config.rasi"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/system/hyprland/modules/70-keybindings.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Rofi configuration and canonical Hyprland launcher binding.
EOF
}

resolve_user_home() {
  getent passwd "$1" | cut -d: -f6
}

validate_user() {
  local username="$1"
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
  [[ "$username" != "root" ]] || die "Rofi configuration must target a normal user."
}

install_configuration() {
  local username="$1"
  local user_home="$2"
  local rofi_directory="${user_home}/.config/rofi"
  local hypr_directory="${user_home}/.config/hypr"

  log_info "Installing Rofi configuration for ${username}."

  install -d -m 0755 -o "$username" -g "$username" "$rofi_directory" "$hypr_directory" "$hypr_directory/modules"
  install -m 0644 -o "$username" -g "$username" "$ROFI_SOURCE" "$rofi_directory/config.rasi"
  install -m 0644 -o "$username" -g "$username" "$KEYBINDINGS_SOURCE" "$hypr_directory/modules/70-keybindings.lua"
}

validate_configuration() {
  local user_home="$1"
  local rofi_config="${user_home}/.config/rofi/config.rasi"
  local keybindings="${user_home}/.config/hypr/modules/70-keybindings.lua"

  [[ -s "$rofi_config" ]] || die "Rofi configuration was not installed."
  [[ -s "$keybindings" ]] || die "Hyprland keybindings module was not installed."

  grep -q 'modi: "drun,run"' "$rofi_config" || die "Rofi drun/run modes are not configured."
  grep -q 'hl.bind("SUPER", "SPACE"' "$keybindings" || die "SUPER+SPACE launcher binding is missing."
  grep -q 'rofi -show drun' "$keybindings" || die "Launcher binding does not invoke Rofi drun mode."

  if grep -Eq 'kb-row-(left|right)[[:space:]]*:' "$rofi_config"; then
    die "Rofi row navigation bindings must not be overridden by the shared configuration."
  fi
}

validate_effective_bindings() {
  local username="$1"
  local binding_output

  log_info "Checking Rofi built-in navigation bindings."
  binding_output="$(runuser -u "$username" -- rofi -list-keybindings 2>/dev/null)" || \
    die "Could not query Rofi keybindings."

  grep -q 'kb-row-left' <<<"$binding_output" || die "Rofi kb-row-left binding is unavailable."
  grep -q 'kb-row-right' <<<"$binding_output" || die "Rofi kb-row-right binding is unavailable."
}

show_result() {
  local username="$1"
  local user_home="$2"

  printf '\nRofi application launcher configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$username"
  printf 'Modes:\n  drun, run\n\n'
  printf 'Binding:\n  SUPER + SPACE -> rofi -show drun\n\n'
  printf 'Configuration:\n  %s/.config/rofi/config.rasi\n\n' "$user_home"
  printf 'Built-in row navigation bindings were preserved.\n'
  printf 'Graphical launcher behavior must be validated from the Hyprland session.\n'
  printf '\nNext step:\n  17-configure-notification-center\n'
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
  require_commands cut getent grep id install runuser
  require_arch_systemd
  require_package_installed rofi "Run 06-install-application-launcher first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_user "$username"
  user_home="$(resolve_user_home "$username")"
  [[ -n "$user_home" && -d "$user_home" ]] || die "Could not resolve a valid home directory for ${username}."

  [[ -s "$ROFI_SOURCE" ]] || die "Shared Rofi configuration is missing."
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  install_configuration "$username" "$user_home"
  validate_configuration "$user_home"
  validate_effective_bindings "$username"
  show_result "$username" "$user_home"
}

main "$@"
