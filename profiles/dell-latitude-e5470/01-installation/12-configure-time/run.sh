#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_TIMEZONE="America/Sao_Paulo"

TIMEZONE="$DEFAULT_TIMEZONE"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [--timezone <area/location>]

Default timezone:
  ${DEFAULT_TIMEZONE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --timezone)
        (($# >= 2)) || die "Missing value for --timezone."
        TIMEZONE="$2"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

validate_timezone() {
  [[ -n "$TIMEZONE" && "$TIMEZONE" != /* && "$TIMEZONE" != *".."* ]] || die "Invalid timezone: $TIMEZONE"
  [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || die "Unknown timezone: $TIMEZONE"
}

show_plan() {
  printf '\nTime configuration\n'
  printf '%s\n\n' '------------------'
  printf 'Timezone:\n  %s\n\n' "$TIMEZONE"
  printf 'RTC policy:\n  UTC\n'
}

confirm_configuration() {
  local confirmation
  printf '\nType TIME to apply the time configuration: '
  read -r confirmation
  [[ "$confirmation" == "TIME" ]] || die "Time configuration was not authorized."
}

configure_time() {
  log_info "Configuring timezone: $TIMEZONE"
  ln --symbolic --force "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  hwclock --systohc --utc
}

validate_configuration() {
  [[ -L /etc/localtime ]] || die "/etc/localtime is not a symbolic link."
  [[ "$(readlink -f /etc/localtime)" == "/usr/share/zoneinfo/$TIMEZONE" ]] || die "/etc/localtime does not point to the expected timezone."
  [[ -s /etc/adjtime ]] || die "/etc/adjtime was not created."
  grep -Fxq 'UTC' /etc/adjtime || die "The hardware clock is not configured to use UTC."
  [[ -n "$(date +%Z)" ]] || die "Unable to determine the configured timezone abbreviation."
}

show_result() {
  printf '\nTime configuration completed successfully.\n\n'
  printf 'Timezone link:\n  /etc/localtime -> %s\n' "$(readlink /etc/localtime)"
  printf 'Current system time:\n  %s\n' "$(date --iso-8601=seconds)"
  printf '\nNext step:\n  13-configure-localization\n'
}

main() {
  require_root
  require_commands date grep hwclock ln readlink
  parse_arguments "$@"
  require_installed_arch_context
  [[ -d /usr/share/zoneinfo ]] || die "Timezone database is unavailable."
  validate_timezone
  show_plan
  confirm_configuration
  configure_time
  validate_configuration
  show_result
}

main "$@"
