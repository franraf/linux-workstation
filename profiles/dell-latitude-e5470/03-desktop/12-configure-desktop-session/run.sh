#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly CONFIG_SOURCE="${REPO_ROOT}/system/hyprland"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <user>

Installs the canonical Hyprland Lua configuration for the target user.
EOF
}

validate_source_tree() {
  [[ -f "${CONFIG_SOURCE}/hyprland.lua" ]] || die "Missing canonical entrypoint: ${CONFIG_SOURCE}/hyprland.lua"

  local module
  for module in 10-environment.lua 20-monitor.lua 30-input.lua 40-general.lua 50-autostart.lua 60-session-lock.lua 70-keybindings.lua 80-appearance.lua; do
    [[ -f "${CONFIG_SOURCE}/modules/${module}" ]] || die "Missing Hyprland module: ${module}"
  done
}

show_plan() {
  printf '\nHyprland desktop session configuration\n'
  printf '%s\n\n' '--------------------------------------'
  printf 'Target user:\n  %s\n' "$TARGET_USER"
  printf 'Source:\n  %s\n' "$CONFIG_SOURCE"
  printf 'Destination:\n  %s/.config/hypr\n' "$TARGET_HOME"
}

confirm_configuration() {
  local confirmation
  printf '\nType CONFIGURE to install the Hyprland configuration: '
  read -r confirmation
  [[ "$confirmation" == "CONFIGURE" ]] || die "Desktop session configuration was not authorized."
}

install_configuration() {
  local target="${TARGET_HOME}/.config/hypr"

  install_user_directory "$target"
  install_user_directory "$target/modules"
  install_user_file "${CONFIG_SOURCE}/hyprland.lua" "$target/hyprland.lua"

  local source_file
  for source_file in "${CONFIG_SOURCE}"/modules/*.lua; do
    install_user_file "$source_file" "$target/modules/$(basename "$source_file")"
  done

  rm -f "$target/hyprland.conf"
}

validate_installed_configuration() {
  local target="${TARGET_HOME}/.config/hypr"

  [[ -f "$target/hyprland.lua" ]] || die "hyprland.lua was not installed."
  [[ ! -e "$target/hyprland.conf" ]] || die "Legacy hyprland.conf is still active."
  [[ "$(stat -c '%U' "$target/hyprland.lua")" == "$TARGET_USER" ]] || die "hyprland.lua has incorrect ownership."
}

show_result() {
  printf '\nHyprland desktop session configuration installed successfully.\n'
  printf '\nNext step:\n  13-configure-status-bar\n'
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && {
    usage
    exit 0
  }
  (($# == 1)) || die "Expected exactly one target user argument."

  require_root
  require_commands basename rm stat
  require_user_config_commands
  require_arch_systemd
  require_package_installed hyprland "Run 02-install-compositor first."

  resolve_normal_user "$1"
  validate_source_tree
  show_plan
  confirm_configuration
  install_configuration
  validate_installed_configuration
  show_result
}

main "$@"
