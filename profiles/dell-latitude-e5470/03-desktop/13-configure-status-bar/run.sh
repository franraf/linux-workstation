#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SOURCE_DIRECTORY="${REPO_ROOT}/system/waybar"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Waybar configuration for the selected workstation user.
EOF
}

resolve_user_home() {
  local username="$1"
  getent passwd "$username" | cut -d: -f6
}

validate_user() {
  local username="$1"
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
  [[ "$username" != "root" ]] || die "Waybar configuration must target a normal user."
}

install_configuration() {
  local username="$1"
  local user_home="$2"
  local target_directory="${user_home}/.config/waybar"

  log_info "Installing Waybar configuration for ${username}."

  install -d -m 0755 -o "$username" -g "$username" "$target_directory" "$target_directory/modules"
  install -m 0644 -o "$username" -g "$username" "${SOURCE_DIRECTORY}/config.jsonc" "$target_directory/config.jsonc"
  install -m 0644 -o "$username" -g "$username" "${SOURCE_DIRECTORY}/style.css" "$target_directory/style.css"

  local source_file
  for source_file in "${SOURCE_DIRECTORY}"/modules/*.jsonc; do
    install -m 0644 -o "$username" -g "$username" "$source_file" "$target_directory/modules/$(basename "$source_file")"
  done
}

validate_configuration_files() {
  local user_home="$1"
  local target_directory="${user_home}/.config/waybar"

  [[ -s "$target_directory/config.jsonc" ]] || die "Waybar config.jsonc was not installed."
  [[ -s "$target_directory/style.css" ]] || die "Waybar style.css was not installed."

  local module
  for module in workspaces window clock network pulseaudio battery tray; do
    [[ -s "$target_directory/modules/${module}.jsonc" ]] || die "Waybar module was not installed: ${module}.jsonc"
  done

  grep -q '"modules-left"' "$target_directory/config.jsonc" || die "Waybar left module group is missing."
  grep -q '"modules-center"' "$target_directory/config.jsonc" || die "Waybar center module group is missing."
  grep -q '"modules-right"' "$target_directory/config.jsonc" || die "Waybar right module group is missing."

  if grep -Eq '"width"[[:space:]]*:' "$target_directory/config.jsonc"; then
    die "Waybar configuration must not define a fixed width."
  fi
}

show_result() {
  local username="$1"
  local user_home="$2"

  printf '\nWaybar configuration installed successfully.\n\n'
  printf 'User:\n  %s\n\n' "$username"
  printf 'Configuration:\n  %s/.config/waybar\n\n' "$user_home"
  printf 'Distribution:\n'
  printf '  left:   workspaces\n'
  printf '  center: active window\n'
  printf '  right:  network, audio, battery, clock, tray\n'
  printf '\nAutostart integration remains in system/hyprland/modules/50-autostart.lua.\n'
  printf '\nNext step:\n  14-configure-session-lock\n'
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
  require_commands basename cut getent grep id install
  require_arch_systemd
  require_package_installed waybar "Run 03-install-status-bar first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_user "$username"
  user_home="$(resolve_user_home "$username")"
  [[ -n "$user_home" && -d "$user_home" ]] || die "Could not resolve a valid home directory for ${username}."

  [[ -s "${SOURCE_DIRECTORY}/config.jsonc" ]] || die "Shared Waybar config is missing."
  [[ -s "${SOURCE_DIRECTORY}/style.css" ]] || die "Shared Waybar style is missing."

  install_configuration "$username" "$user_home"
  validate_configuration_files "$user_home"
  show_result "$username" "$user_home"
}

main "$@"
