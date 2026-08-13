#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SWAYNC_SOURCE="${REPO_ROOT}/system/swaync/config.json"
readonly AUTOSTART_SOURCE="${REPO_ROOT}/system/hyprland/modules/50-autostart.lua"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/system/hyprland/modules/70-keybindings.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared SwayNC configuration and its Hyprland integrations.
EOF
}

resolve_user_home() {
  getent passwd "$1" | cut -d: -f6
}

validate_user() {
  local username="$1"
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
  [[ "$username" != "root" ]] || die "Notification center configuration must target a normal user."
}

install_configuration() {
  local username="$1"
  local user_home="$2"
  local swaync_directory="${user_home}/.config/swaync"
  local hypr_directory="${user_home}/.config/hypr"

  log_info "Installing SwayNC configuration for ${username}."

  install -d -m 0755 -o "$username" -g "$username" "$swaync_directory" "$hypr_directory" "$hypr_directory/modules"
  install -m 0644 -o "$username" -g "$username" "$SWAYNC_SOURCE" "$swaync_directory/config.json"
  install -m 0644 -o "$username" -g "$username" "$AUTOSTART_SOURCE" "$hypr_directory/modules/50-autostart.lua"
  install -m 0644 -o "$username" -g "$username" "$KEYBINDINGS_SOURCE" "$hypr_directory/modules/70-keybindings.lua"
}

validate_configuration() {
  local user_home="$1"
  local swaync_config="${user_home}/.config/swaync/config.json"
  local autostart="${user_home}/.config/hypr/modules/50-autostart.lua"
  local keybindings="${user_home}/.config/hypr/modules/70-keybindings.lua"

  [[ -s "$swaync_config" ]] || die "SwayNC configuration was not installed."
  [[ -s "$autostart" ]] || die "Hyprland autostart module was not installed."
  [[ -s "$keybindings" ]] || die "Hyprland keybindings module was not installed."

  grep -q '"notifications"' "$swaync_config" || die "SwayNC notifications widget is missing."
  grep -q 'pidof swaync || swaync' "$autostart" || die "SwayNC autostart entry is missing."
  grep -q 'hl.bind("SUPER", "N"' "$keybindings" || die "SUPER+N notification center binding is missing."
  grep -q 'swaync-client -t' "$keybindings" || die "Notification center binding does not invoke swaync-client."

  local count
  count="$(grep -c 'pidof swaync || swaync' "$autostart")"
  [[ "$count" -eq 1 ]] || die "SwayNC must appear exactly once in the autostart registry."
}

validate_notification_daemons() {
  local user_home="$1"
  local autostart="${user_home}/.config/hypr/modules/50-autostart.lua"

  local conflicting_daemons=(dunst mako)
  local daemon

  for daemon in "${conflicting_daemons[@]}"; do
    if grep -Eq "(^|[^[:alnum:]_-])${daemon}([^[:alnum:]_-]|$)" "$autostart"; then
      die "Conflicting notification daemon found in Hyprland autostart: ${daemon}"
    fi
  done
}

show_result() {
  local username="$1"
  local user_home="$2"

  printf '\nSwayNC notification center configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$username"
  printf 'Configuration:\n  %s/.config/swaync/config.json\n\n' "$user_home"
  printf 'Autostart:\n  swaync (guarded, single entry)\n\n'
  printf 'Binding:\n  SUPER + N -> swaync-client -t\n\n'
  printf 'Notification delivery and history must be validated from the graphical session with notify-send.\n'
  printf '\nNext step:\n  18-configure-terminal-emulator\n'
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
  require_package_installed swaync "Run 07-install-notification-center first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_user "$username"
  user_home="$(resolve_user_home "$username")"
  [[ -n "$user_home" && -d "$user_home" ]] || die "Could not resolve a valid home directory for ${username}."

  [[ -s "$SWAYNC_SOURCE" ]] || die "Shared SwayNC configuration is missing."
  [[ -s "$AUTOSTART_SOURCE" ]] || die "Shared Hyprland autostart module is missing."
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  install_configuration "$username" "$user_home"
  validate_configuration "$user_home"
  validate_notification_daemons "$user_home"
  show_result "$username" "$user_home"
}

main "$@"
