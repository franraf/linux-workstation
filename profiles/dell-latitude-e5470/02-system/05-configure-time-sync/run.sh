#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly SOURCE_FILE="${REPO_ROOT}/system/systemd/timesyncd/10-linux-workstation.conf"
readonly CONFIG_FILE="/etc/systemd/timesyncd.conf.d/10-linux-workstation.conf"
readonly TIME_SYNC_SERVICE="systemd-timesyncd.service"

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
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

confirm_configuration() {
  local confirmation
  printf '\nType TIMESYNC to apply the configuration: '
  read -r confirmation
  [[ "$confirmation" == "TIMESYNC" ]] || die "Time synchronization configuration was not authorized."
}

main() {
  require_root
  require_commands cmp systemctl timedatectl
  require_arch_systemd
  require_system_config_commands
  parse_arguments "$@"

  systemctl cat "$TIME_SYNC_SERVICE" >/dev/null 2>&1 || die "${TIME_SYNC_SERVICE} is unavailable."

  printf '\nTime synchronization\n--------------------\n\nSource:\n  %s\n\nDestination:\n  %s\n' "$SOURCE_FILE" "$CONFIG_FILE"
  confirm_configuration

  install_system_file "$SOURCE_FILE" "$CONFIG_FILE"
  validate_system_file_matches "$SOURCE_FILE" "$CONFIG_FILE"

  log_info "Enabling network time synchronization."
  systemctl enable "$TIME_SYNC_SERVICE"
  timedatectl set-ntp true
  systemctl restart "$TIME_SYNC_SERVICE"

  systemctl is-enabled --quiet "$TIME_SYNC_SERVICE" || die "${TIME_SYNC_SERVICE} is not enabled."
  systemctl is-active --quiet "$TIME_SYNC_SERVICE" || die "${TIME_SYNC_SERVICE} is not active."
  [[ "$(timedatectl show --property=NTP --value)" == "yes" ]] || die "Network time synchronization is not enabled."

  if [[ "$(timedatectl show --property=NTPSynchronized --value)" != "yes" ]]; then
    log_warn "The system is not synchronized yet; this may be normal immediately after enabling timesyncd."
  fi

  printf '\nTime synchronization configured successfully.\n\nNext step:\n  06-configure-journald\n'
}

main "$@"
