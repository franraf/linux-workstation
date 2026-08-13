#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly HYPRIDLE_SOURCE="${REPO_ROOT}/system/hypridle/hypridle.conf"
readonly AUTOSTART_SOURCE="${REPO_ROOT}/system/hyprland/modules/50-autostart.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared Hypridle lifecycle policy and canonical Hyprland autostart registry.
EOF
}

resolve_user_home() {
  getent passwd "$1" | cut -d: -f6
}

validate_user() {
  local username="$1"
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
  [[ "$username" != "root" ]] || die "Session lifecycle configuration must target a normal user."
}

install_configuration() {
  local username="$1"
  local user_home="$2"
  local hypr_directory="${user_home}/.config/hypr"

  log_info "Installing Hypridle lifecycle configuration for ${username}."

  install -d -m 0755 -o "$username" -g "$username" "$hypr_directory" "$hypr_directory/modules"
  install -m 0644 -o "$username" -g "$username" "$HYPRIDLE_SOURCE" "$hypr_directory/hypridle.conf"
  install -m 0644 -o "$username" -g "$username" "$AUTOSTART_SOURCE" "$hypr_directory/modules/50-autostart.lua"
}

validate_configuration() {
  local user_home="$1"
  local hypr_directory="${user_home}/.config/hypr"

  [[ -s "$hypr_directory/hypridle.conf" ]] || die "Hypridle configuration was not installed."
  [[ -s "$hypr_directory/modules/50-autostart.lua" ]] || die "Hyprland autostart module was not installed."

  grep -q 'lock_cmd = pidof hyprlock || hyprlock' "$hypr_directory/hypridle.conf" || \
    die "Hypridle lock command is missing."
  grep -q 'timeout = 300' "$hypr_directory/hypridle.conf" || die "Automatic lock timeout is missing."
  grep -q 'timeout = 600' "$hypr_directory/hypridle.conf" || die "Display power timeout is missing."
  grep -q 'timeout = 1800' "$hypr_directory/hypridle.conf" || die "Suspend timeout is missing."
  grep -q 'pidof hypridle || hypridle' "$hypr_directory/modules/50-autostart.lua" || \
    die "Hypridle autostart entry is missing."

  local count
  count="$(grep -c 'pidof hypridle || hypridle' "$hypr_directory/modules/50-autostart.lua")"
  [[ "$count" -eq 1 ]] || die "Hypridle must appear exactly once in the autostart registry."
}

show_result() {
  local username="$1"
  local user_home="$2"

  printf '\nSession lifecycle configuration installed successfully.\n\n'
  printf 'User:\n  %s\n\n' "$username"
  printf 'Policy:\n'
  printf '  5 min  -> lock session\n'
  printf '  10 min -> display off\n'
  printf '  30 min -> suspend\n\n'
  printf 'Configuration:\n  %s/.config/hypr/hypridle.conf\n\n' "$user_home"
  printf 'Autostart:\n  %s/.config/hypr/modules/50-autostart.lua\n\n' "$user_home"
  printf 'Runtime lock, DPMS, suspend and resume behavior must be validated from the graphical session.\n'
  printf '\nNext step:\n  16-configure-application-launcher\n'
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
  require_package_installed hypridle "Run 05-install-idle-manager first."
  require_package_installed hyprlock "Run 04-install-screen-locker first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_user "$username"
  user_home="$(resolve_user_home "$username")"
  [[ -n "$user_home" && -d "$user_home" ]] || die "Could not resolve a valid home directory for ${username}."

  [[ -s "$HYPRIDLE_SOURCE" ]] || die "Shared Hypridle configuration is missing."
  [[ -s "$AUTOSTART_SOURCE" ]] || die "Shared Hyprland autostart module is missing."

  install_configuration "$username" "$user_home"
  validate_configuration "$user_home"
  show_result "$username" "$user_home"
}

main "$@"
