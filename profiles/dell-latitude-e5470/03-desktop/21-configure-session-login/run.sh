#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly GREETD_SOURCE="${REPO_ROOT}/system/greetd/config.toml"
readonly GREETD_TARGET="/etc/greetd/config.toml"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Configures greetd + tuigreet to authenticate before starting Hyprland.
The personal account is never configured for autologin.
EOF
}

validate_target_user() {
  local username="$1"

  [[ "$username" != "root" ]] || die "The graphical session must use a normal user."
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"
}

validate_no_autologin() {
  local username="$1"
  local getty_override="/etc/systemd/system/getty@tty1.service.d"
  local profile

  log_info "Checking for conflicting autologin mechanisms."

  if [[ -d "$getty_override" ]] && grep -Rqs -- '--autologin' "$getty_override"; then
    die "A tty1 autologin override still exists under ${getty_override}. Remove it before enabling greetd."
  fi

  local user_home
  user_home="$(getent passwd "$username" | cut -d: -f6)"

  for profile in .bash_profile .profile .zprofile; do
    if [[ -f "${user_home}/${profile}" ]] && grep -Eq '(^|[[:space:]])(start-hyprland|Hyprland)([[:space:]]|$)' "${user_home}/${profile}"; then
      die "Automatic Hyprland startup was found in ${user_home}/${profile}. Remove it before enabling greetd."
    fi
  done
}

install_configuration() {
  log_info "Installing greetd configuration."

  install -d -m 0755 /etc/greetd
  install -m 0644 "$GREETD_SOURCE" "$GREETD_TARGET"
}

validate_configuration() {
  [[ -s "$GREETD_TARGET" ]] || die "greetd configuration was not installed."

  grep -Fq 'command = "/usr/bin/tuigreet --time --asterisks --cmd /usr/bin/start-hyprland"' "$GREETD_TARGET" || \
    die "greetd does not launch tuigreet with start-hyprland."
  grep -Fq 'user = "greeter"' "$GREETD_TARGET" || die "greetd default session must run as greeter."

  getent passwd greeter >/dev/null 2>&1 || die "The greeter system account does not exist."
  [[ -x /usr/bin/tuigreet ]] || die "/usr/bin/tuigreet is unavailable."
  [[ -x /usr/bin/start-hyprland ]] || die "/usr/bin/start-hyprland is unavailable."
}

enable_service() {
  log_info "Enabling greetd for the next boot."
  systemctl enable greetd.service >/dev/null
  systemctl is-enabled --quiet greetd.service || die "greetd.service was not enabled."
}

show_result() {
  printf '\nSession login configured successfully.\n\n'
  printf 'Flow:\n'
  printf '  boot -> greetd -> tuigreet -> authentication -> start-hyprland -> Hyprland\n\n'
  printf 'Security:\n'
  printf '  - no personal-account autologin configured\n'
  printf '  - greetd enabled for next boot\n'
  printf '  - service was not started immediately by this script\n\n'
  printf 'Reboot validation remains mandatory before completing the phase.\n'
  printf '\nNext step:\n  22-desktop-validation\n'
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands cut getent grep id install systemctl
  require_arch_systemd
  require_package_installed greetd "Run 11-install-session-login first."
  require_package_installed greetd-tuigreet "Run 11-install-session-login first."
  require_package_installed hyprland "Run 02-install-compositor first."

  validate_target_user "$1"
  validate_no_autologin "$1"
  [[ -s "$GREETD_SOURCE" ]] || die "Shared greetd configuration is missing."

  install_configuration
  validate_configuration
  enable_service
  show_result
}

main "$@"
