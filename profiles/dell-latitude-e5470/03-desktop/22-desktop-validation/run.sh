#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly TEST_DIRECTORY="${REPO_ROOT}/tests/desktop"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Runs the final validation gate for phase 03-desktop.
Execute it as the authenticated graphical user from inside Hyprland.
EOF
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
  (($# == 0)) || die "This script does not accept arguments."
  [[ $EUID -ne 0 ]] || die "Run desktop validation as the authenticated graphical user, not root."

  require_commands bash grep hyprctl pgrep systemctl wc
  require_package_installed hyprland "Run 02-install-compositor first."
  require_package_installed waybar "Run 03-install-status-bar first."
  require_package_installed hyprlock "Run 04-install-screen-locker first."
  require_package_installed hypridle "Run 05-install-idle-manager first."
  require_package_installed rofi "Run 06-install-application-launcher first."
  require_package_installed swaync "Run 07-install-notification-center first."
  require_package_installed kitty "Run 08-install-terminal-emulator first."
  require_package_installed thunar "Run 09-install-file-manager first."
  require_package_installed greetd "Run 11-install-session-login first."

  [[ -x "${TEST_DIRECTORY}/static-config.sh" ]] || chmod +x "${TEST_DIRECTORY}/static-config.sh"
  [[ -x "${TEST_DIRECTORY}/runtime-session.sh" ]] || chmod +x "${TEST_DIRECTORY}/runtime-session.sh"

  log_info "Running static desktop configuration tests."
  "${TEST_DIRECTORY}/static-config.sh"

  log_info "Running live Hyprland session tests."
  "${TEST_DIRECTORY}/runtime-session.sh"

  printf '\nAutomated desktop validation passed.\n'
  printf 'Complete the manual checks printed above before marking phase 03-desktop complete.\n'
}

main "$@"
