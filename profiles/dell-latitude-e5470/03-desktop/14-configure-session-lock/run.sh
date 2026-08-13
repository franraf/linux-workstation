#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly HYPRLOCK_SOURCE="${REPO_ROOT}/system/hyprlock/hyprlock.conf"
readonly HYPRLAND_SOURCE="${REPO_ROOT}/system/hyprland/modules/60-session-lock.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Hyprlock configuration and the canonical Hyprland session-lock module.
EOF
}

resolve_user_home() {
  getent passwd "$1" | cut -d: -f6
}

validate_user() {
  local username="$1"
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
  [[ "$username" != "root" ]] || die "Session lock configuration must target a normal user."
}

install_configuration() {
  local username="$1"
  local user_home="$2"
  local hypr_directory="${user_home}/.config/hypr"

  log_info "Installing Hyprlock configuration for ${username}."

  install -d -m 0755 -o "$username" -g "$username" "$hypr_directory" "$hypr_directory/modules"
  install -m 0644 -o "$username" -g "$username" "$HYPRLOCK_SOURCE" "$hypr_directory/hyprlock.conf"
  install -m 0644 -o "$username" -g "$username" "$HYPRLAND_SOURCE" "$hypr_directory/modules/60-session-lock.lua"
}

validate_configuration() {
  local user_home="$1"
  local hypr_directory="${user_home}/.config/hypr"

  [[ -s "$hypr_directory/hyprlock.conf" ]] || die "Hyprlock configuration was not installed."
  [[ -s "$hypr_directory/modules/60-session-lock.lua" ]] || die "Session-lock Hyprland module was not installed."

  grep -q 'hl.bind("SUPER", "L"' "$hypr_directory/modules/60-session-lock.lua" || \
    die "SUPER+L session-lock binding is missing."

  grep -q 'hyprlock' "$hypr_directory/modules/60-session-lock.lua" || \
    die "Session-lock binding does not invoke Hyprlock."
}

show_result() {
  local username="$1"
  local user_home="$2"

  printf '\nSession lock configuration installed successfully.\n\n'
  printf 'User:\n  %s\n\n' "$username"
  printf 'Hyprlock configuration:\n  %s/.config/hypr/hyprlock.conf\n\n' "$user_home"
  printf 'Hyprland module:\n  %s/.config/hypr/modules/60-session-lock.lua\n\n' "$user_home"
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

  local username="$1"
  local user_home

  require_root
  require_commands cut getent grep id install
  require_arch_systemd
  require_package_installed hyprlock "Run 04-install-screen-locker first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_user "$username"
  user_home="$(resolve_user_home "$username")"
  [[ -n "$user_home" && -d "$user_home" ]] || die "Could not resolve a valid home directory for ${username}."

  [[ -s "$HYPRLOCK_SOURCE" ]] || die "Shared Hyprlock configuration is missing."
  [[ -s "$HYPRLAND_SOURCE" ]] || die "Shared session-lock module is missing."

  install_configuration "$username" "$user_home"
  validate_configuration "$user_home"
  show_result "$username" "$user_home"
}

main "$@"
