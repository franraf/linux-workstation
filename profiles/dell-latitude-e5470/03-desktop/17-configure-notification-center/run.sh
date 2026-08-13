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
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared SwayNC configuration and its Hyprland integrations.
EOF
}

install_configuration() {
  local swaync_directory hypr_directory
  swaync_directory="$(user_config_path swaync)"
  hypr_directory="$(user_config_path hypr)"

  log_info "Installing SwayNC configuration for ${TARGET_USER}."
  install_user_directory "$swaync_directory"
  install_user_directory "$hypr_directory"
  install_user_directory "${hypr_directory}/modules"
  install_user_file "$SWAYNC_SOURCE" "${swaync_directory}/config.json"
  install_user_file "$AUTOSTART_SOURCE" "${hypr_directory}/modules/50-autostart.lua"
  install_user_file "$KEYBINDINGS_SOURCE" "${hypr_directory}/modules/70-keybindings.lua"
}

validate_configuration() {
  local swaync_config autostart keybindings
  swaync_config="$(user_config_path swaync/config.json)"
  autostart="$(user_config_path hypr/modules/50-autostart.lua)"
  keybindings="$(user_config_path hypr/modules/70-keybindings.lua)"

  [[ -s "$swaync_config" ]] || die "SwayNC configuration was not installed."
  [[ -s "$autostart" ]] || die "Hyprland autostart module was not installed."
  [[ -s "$keybindings" ]] || die "Hyprland keybindings module was not installed."
  grep -q '"notifications"' "$swaync_config" || die "SwayNC notifications widget is missing."
  [[ "$(grep -c 'pidof swaync || swaync' "$autostart")" -eq 1 ]] || die "SwayNC must appear exactly once in autostart."
  grep -q 'hl.bind("SUPER", "N"' "$keybindings" || die "SUPER+N notification binding is missing."
  grep -q 'swaync-client -t' "$keybindings" || die "Notification binding does not invoke swaync-client."
}

validate_notification_daemons() {
  local autostart daemon
  autostart="$(user_config_path hypr/modules/50-autostart.lua)"

  for daemon in dunst mako; do
    if grep -Eq "(^|[^[:alnum:]_-])${daemon}([^[:alnum:]_-]|$)" "$autostart"; then
      die "Conflicting notification daemon found in Hyprland autostart: ${daemon}"
    fi
  done
}

show_result() {
  printf '\nSwayNC notification center configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Autostart:\n  swaync (guarded, single entry)\n\n'
  printf 'Binding:\n  SUPER + N -> swaync-client -t\n\n'
  printf 'Notification delivery and history must be validated from the graphical session with notify-send.\n'
  printf '\nNext step:\n  18-configure-terminal-emulator\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands grep
  require_user_config_commands
  require_arch_systemd
  require_package_installed swaync "Run 07-install-notification-center first."
  require_package_installed hyprland "Run 02-install-compositor first."
  resolve_normal_user "$1"

  [[ -s "$SWAYNC_SOURCE" ]] || die "Shared SwayNC configuration is missing."
  [[ -s "$AUTOSTART_SOURCE" ]] || die "Shared Hyprland autostart module is missing."
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  install_configuration
  validate_configuration
  validate_notification_daemons
  show_result
}

main "$@"
