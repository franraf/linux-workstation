#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly SOURCE_FILE="${REPO_ROOT}/system/systemd/10-linux-workstation.conf"
readonly CONFIG_FILE="/etc/systemd/system.conf.d/10-linux-workstation.conf"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/system-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Canonical source:
  ${SOURCE_FILE}

Destination:
  ${CONFIG_FILE}
EOF
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
  printf '\nType SYSTEMD to apply the configuration: '
  read -r confirmation
  [[ "$confirmation" == "SYSTEMD" ]] || die "systemd configuration was not authorized."
}

main() {
  require_root
  require_commands cmp systemctl systemd-analyze
  require_arch_systemd
  require_system_config_commands
  parse_arguments "$@"

  [[ -f "$SOURCE_FILE" ]] || die "Canonical systemd configuration is missing: $SOURCE_FILE"

  printf '\nsystemd configuration\n---------------------\n\nSource:\n  %s\n\nDestination:\n  %s\n' "$SOURCE_FILE" "$CONFIG_FILE"
  confirm_configuration

  install_system_file "$SOURCE_FILE" "$CONFIG_FILE"
  validate_system_file_matches "$SOURCE_FILE" "$CONFIG_FILE"

  systemd-analyze cat-config systemd/system.conf >/dev/null || die "systemd could not parse the manager configuration."

  log_info "Reloading systemd manager configuration."
  systemctl daemon-reexec

  printf '\nsystemd configured successfully.\n\nNext step:\n  05-configure-time-sync\n'
}

main "$@"
