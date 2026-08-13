#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SOURCE_FILE="${REPO_ROOT}/system/systemd/journald/10-linux-workstation.conf"
readonly CONFIG_FILE="/etc/systemd/journald.conf.d/10-linux-workstation.conf"
readonly JOURNAL_DIRECTORY="/var/log/journal"
readonly JOURNAL_SERVICE="systemd-journald.service"

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
  printf '\nType JOURNAL to apply the configuration: '
  read -r confirmation
  [[ "$confirmation" == "JOURNAL" ]] || die "Journal configuration was not authorized."
}

main() {
  require_root
  require_commands cmp install journalctl stat systemctl systemd-analyze systemd-tmpfiles
  require_arch_systemd
  require_system_config_commands
  parse_arguments "$@"

  systemctl cat "$JOURNAL_SERVICE" >/dev/null 2>&1 || die "${JOURNAL_SERVICE} is unavailable."

  printf '\nJournal configuration\n---------------------\n\nSource:\n  %s\n\nDestination:\n  %s\n' "$SOURCE_FILE" "$CONFIG_FILE"
  confirm_configuration

  install_system_file "$SOURCE_FILE" "$CONFIG_FILE"
  validate_system_file_matches "$SOURCE_FILE" "$CONFIG_FILE"
  systemd-analyze cat-config systemd/journald.conf >/dev/null || die "systemd could not parse journald configuration."

  log_info "Preparing persistent journal storage."
  install --directory --owner root --group systemd-journal --mode 2755 "$JOURNAL_DIRECTORY"
  systemd-tmpfiles --create --prefix "$JOURNAL_DIRECTORY"

  log_info "Restarting systemd-journald."
  systemctl restart "$JOURNAL_SERVICE"
  systemctl is-active --quiet "$JOURNAL_SERVICE" || die "${JOURNAL_SERVICE} did not return to the active state."

  journalctl --flush
  journalctl --directory "$JOURNAL_DIRECTORY" --no-pager --lines=1 >/dev/null 2>&1 || die "Persistent journal storage could not be read."
  journalctl --verify >/dev/null || die "Journal verification failed."

  printf '\nJournald configured successfully.\n\nNext step:\n  07-configure-zram\n'
}

main "$@"
