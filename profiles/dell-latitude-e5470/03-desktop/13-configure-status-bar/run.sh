#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SOURCE_DIRECTORY="${REPO_ROOT}/system/waybar"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>
EOF
}

install_configuration() {
  local target="${TARGET_HOME}/.config/waybar"

  log_info "Installing Waybar configuration for ${TARGET_USER}."
  install_user_directory "$target"
  install_user_directory "$target/modules"
  install_user_file "${SOURCE_DIRECTORY}/config.jsonc" "$target/config.jsonc"
  install_user_file "${SOURCE_DIRECTORY}/style.css" "$target/style.css"

  local source_file
  for source_file in "${SOURCE_DIRECTORY}"/modules/*.jsonc; do
    install_user_file "$source_file" "$target/modules/$(basename "$source_file")"
  done
}

validate_configuration_files() {
  local target="${TARGET_HOME}/.config/waybar"

  [[ -s "$target/config.jsonc" ]] || die "Waybar config.jsonc was not installed."
  [[ -s "$target/style.css" ]] || die "Waybar style.css was not installed."

  local module
  for module in workspaces window clock network pulseaudio battery tray; do
    [[ -s "$target/modules/${module}.jsonc" ]] || die "Waybar module was not installed: ${module}.jsonc"
  done

  grep -q '"modules-left"' "$target/config.jsonc" || die "Waybar left module group is missing."
  grep -q '"modules-center"' "$target/config.jsonc" || die "Waybar center module group is missing."
  grep -q '"modules-right"' "$target/config.jsonc" || die "Waybar right module group is missing."
  ! grep -Eq '"width"[[:space:]]*:' "$target/config.jsonc" || die "Waybar configuration must not define a fixed width."
}

show_result() {
  printf '\nWaybar configuration installed successfully.\n'
  printf '\nNext step:\n  14-configure-session-lock\n'
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands basename grep
  require_user_config_commands
  require_arch_systemd
  require_package_installed waybar "Run 03-install-status-bar first."
  require_package_installed hyprland "Run 02-install-compositor first."

  resolve_normal_user "$1"
  [[ -s "${SOURCE_DIRECTORY}/config.jsonc" ]] || die "Shared Waybar config is missing."
  [[ -s "${SOURCE_DIRECTORY}/style.css" ]] || die "Shared Waybar style is missing."

  install_configuration
  validate_configuration_files
  show_result
}

main "$@"
