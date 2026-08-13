#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SOURCE_FILE="${REPO_ROOT}/system/openssh/10-linux-workstation.conf"
readonly CONFIG_FILE="/etc/ssh/sshd_config.d/10-linux-workstation.conf"
readonly SSH_PACKAGE="openssh"
readonly SSH_SERVICE="sshd.service"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/system-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  printf 'Usage:\n  sudo ./%s\n\nCanonical source:\n  %s\n' "$SCRIPT_NAME" "$SOURCE_FILE"
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

confirm_configuration() {
  local confirmation
  printf '\nType SSH to configure OpenSSH: '
  read -r confirmation
  [[ "$confirmation" == "SSH" ]] || die "OpenSSH configuration was not authorized."
}

validate_effective_option() {
  local effective_config="$1"
  local option="$2"
  local expected="$3"

  awk -v option="$option" -v expected="$expected" '
    tolower($1) == tolower(option) && tolower($2) == tolower(expected) { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' <<<"$effective_config" || die "${option}=${expected} is not effective."
}

main() {
  require_root
  require_commands cmp find pacman sshd ssh-keygen systemctl
  require_arch_systemd
  require_system_config_commands
  parse_arguments "$@"

  if ! pacman -Q "$SSH_PACKAGE" >/dev/null 2>&1; then
    log_info "Installing ${SSH_PACKAGE}."
    pacman -S --needed "$SSH_PACKAGE"
  fi

  systemctl cat "$SSH_SERVICE" >/dev/null 2>&1 || die "${SSH_SERVICE} is unavailable."

  printf '\nOpenSSH configuration\n---------------------\n\nSource:\n  %s\n\nDestination:\n  %s\n' "$SOURCE_FILE" "$CONFIG_FILE"
  confirm_configuration

  install_system_file "$SOURCE_FILE" "$CONFIG_FILE"
  validate_system_file_matches "$SOURCE_FILE" "$CONFIG_FILE"

  if ! find /etc/ssh -maxdepth 1 -type f -name 'ssh_host_*_key' -print -quit | grep -q .; then
    log_info "Generating OpenSSH host keys."
    ssh-keygen -A
  fi

  sshd -t || die "OpenSSH configuration validation failed."

  local effective_config
  effective_config="$(sshd -T)"
  validate_effective_option "$effective_config" PermitRootLogin no
  validate_effective_option "$effective_config" PubkeyAuthentication yes
  validate_effective_option "$effective_config" PasswordAuthentication yes
  validate_effective_option "$effective_config" PermitEmptyPasswords no
  validate_effective_option "$effective_config" KbdInteractiveAuthentication no
  validate_effective_option "$effective_config" X11Forwarding no

  systemctl enable "$SSH_SERVICE"
  systemctl restart "$SSH_SERVICE"
  systemctl is-enabled --quiet "$SSH_SERVICE" || die "${SSH_SERVICE} is not enabled."
  systemctl is-active --quiet "$SSH_SERVICE" || die "${SSH_SERVICE} is not active."

  printf '\nOpenSSH configured successfully.\n\nNext step:\n  11-install-base-packages\n'
}

main "$@"
