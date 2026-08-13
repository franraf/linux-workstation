#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly CONFIG_SOURCE="${REPO_ROOT}/system/hyprland"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <user>

Installs the canonical Hyprland Lua configuration for the target user.

Configuration source:
  ${CONFIG_SOURCE}
EOF
}

resolve_target_user() {
  TARGET_USER="${1:-}"
  [[ -n "$TARGET_USER" ]] || die "Target user is required. Usage: sudo ./$SCRIPT_NAME <user>"
  [[ "$TARGET_USER" != "root" ]] || die "The graphical session must not be configured for root."

  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  [[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || die "Home directory for user '$TARGET_USER' was not found."

  TARGET_GROUP="$(id -gn "$TARGET_USER")"
  readonly TARGET_USER TARGET_HOME TARGET_GROUP
  readonly CONFIG_TARGET="${TARGET_HOME}/.config/hypr"
}

validate_source_tree() {
  log_info "Validating canonical Hyprland configuration source."

  [[ -f "${CONFIG_SOURCE}/hyprland.lua" ]] || die "Missing canonical entrypoint: ${CONFIG_SOURCE}/hyprland.lua"

  local module
  for module in \
    10-environment.lua \
    20-monitor.lua \
    30-input.lua \
    40-general.lua \
    50-autostart.lua \
    60-session-lock.lua \
    70-keybindings.lua \
    80-appearance.lua; do
    [[ -f "${CONFIG_SOURCE}/modules/${module}" ]] || die "Missing Hyprland module: ${module}"
  done
}

show_plan() {
  printf '\nHyprland desktop session configuration\n'
  printf '%s\n\n' '--------------------------------------'
  printf 'Target user:\n  %s\n' "$TARGET_USER"
  printf 'Target home:\n  %s\n' "$TARGET_HOME"
  printf 'Source:\n  %s\n' "$CONFIG_SOURCE"
  printf 'Destination:\n  %s\n\n' "$CONFIG_TARGET"
  printf 'This step will replace the managed Hyprland configuration with the repository version.\n'
}

confirm_configuration() {
  local confirmation
  printf '\nType CONFIGURE to install the Hyprland configuration: '
  read -r confirmation
  [[ "$confirmation" == "CONFIGURE" ]] || die "Desktop session configuration was not authorized."
}

install_configuration() {
  log_info "Installing Hyprland Lua configuration."

  install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "$CONFIG_TARGET"
  install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "${CONFIG_TARGET}/modules"

  install -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
    "${CONFIG_SOURCE}/hyprland.lua" "${CONFIG_TARGET}/hyprland.lua"

  local source_file
  for source_file in "${CONFIG_SOURCE}"/modules/*.lua; do
    install -m 0644 -o "$TARGET_USER" -g "$TARGET_GROUP" \
      "$source_file" "${CONFIG_TARGET}/modules/$(basename "$source_file")"
  done

  # ADR-0010: Lua is canonical; legacy Hyprlang entrypoints must not remain active.
  rm -f "${CONFIG_TARGET}/hyprland.conf"
}

validate_installed_configuration() {
  log_info "Validating installed configuration tree."

  [[ -f "${CONFIG_TARGET}/hyprland.lua" ]] || die "hyprland.lua was not installed."
  [[ ! -e "${CONFIG_TARGET}/hyprland.conf" ]] || die "Legacy hyprland.conf is still active."

  local module
  for module in \
    10-environment.lua \
    20-monitor.lua \
    30-input.lua \
    40-general.lua \
    50-autostart.lua \
    60-session-lock.lua \
    70-keybindings.lua \
    80-appearance.lua; do
    [[ -f "${CONFIG_TARGET}/modules/${module}" ]] || die "Installed module missing: ${module}"
  done

  [[ "$(stat -c '%U' "${CONFIG_TARGET}/hyprland.lua")" == "$TARGET_USER" ]] || die "hyprland.lua has incorrect ownership."
}

show_result() {
  printf '\nHyprland desktop session configuration installed successfully.\n\n'
  printf 'Canonical entrypoint:\n  %s\n' "${CONFIG_TARGET}/hyprland.lua"
  printf '\nThe configuration will be functionally validated inside Hyprland with hyprctl configerrors.\n'
  printf '\nNext step:\n  13-configure-status-bar\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  (($# == 1)) || die "Expected exactly one target user argument."

  require_root
  require_commands basename cut getent id install rm stat
  require_arch_systemd
  require_package_installed hyprland "Run 02-install-compositor first."

  resolve_target_user "$1"
  validate_source_tree
  show_plan
  confirm_configuration
  install_configuration
  validate_installed_configuration
  show_result
}

main "$@"
