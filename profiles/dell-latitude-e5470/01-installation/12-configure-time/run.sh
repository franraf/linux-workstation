```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TIMEZONE="America/Sao_Paulo"

TIMEZONE="$DEFAULT_TIMEZONE"

log() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  local line_number=$1

  printf '[ERROR] %s failed at line %s with exit code %s.\n' \
    "$SCRIPT_NAME" \
    "$line_number" \
    "$exit_code" >&2

  exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [options]

Options:
  --timezone <area/location>
      IANA timezone to configure.
      Default: ${DEFAULT_TIMEZONE}

  --help, -h
      Show this help message.

Examples:
  ./$SCRIPT_NAME

  ./$SCRIPT_NAME --timezone America/Sao_Paulo

This script must run inside the installed system or through arch-chroot.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    date
    hwclock
    ln
    readlink
  )

  local command_name

  for command_name in "${commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      die "Required command not found: $command_name"
  done
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --timezone)
        (($# >= 2)) ||
          die "Missing value for --timezone."

        TIMEZONE="$2"
        shift 2
        ;;

      --help | -h)
        usage
        exit 0
        ;;

      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

validate_execution_context() {
  [[ -f /etc/os-release ]] ||
    die "The current root does not contain /etc/os-release."

  grep -q '^ID=arch$' /etc/os-release ||
    die "This script must run inside the installed Arch Linux system."

  [[ -s /etc/fstab ]] ||
    die "The installed system fstab is missing or empty."

  [[ -d /usr/share/zoneinfo ]] ||
    die "Timezone database is unavailable."

}

validate_timezone() {
  [[ -n "$TIMEZONE" ]] ||
    die "Timezone cannot be empty."

  [[ "$TIMEZONE" != /* ]] ||
    die "Timezone must be relative to /usr/share/zoneinfo."

  [[ "$TIMEZONE" != *".."* ]] ||
    die "Timezone cannot contain parent-directory references."

  [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] ||
    die "Unknown timezone: $TIMEZONE"
}

show_plan() {
  cat <<EOF

Time configuration
------------------

Timezone:       $TIMEZONE
Zoneinfo file:  /usr/share/zoneinfo/$TIMEZONE
Localtime link: /etc/localtime
RTC policy:     UTC
Adjtime file:   /etc/adjtime
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType TIME to apply the time configuration: '
  read -r confirmation

  [[ "$confirmation" == "TIME" ]] ||
    die "Time configuration was not authorized."
}

configure_timezone() {
  log "Configuring timezone: $TIMEZONE"

  ln \
    --symbolic \
    --force \
    "/usr/share/zoneinfo/$TIMEZONE" \
    /etc/localtime
}

configure_hardware_clock() {
  log "Writing the system clock to the hardware clock using UTC."

  hwclock --systohc --utc
}

validate_localtime() {
  local expected_target
  local actual_target

  [[ -L /etc/localtime ]] ||
    die "/etc/localtime is not a symbolic link."

  expected_target="/usr/share/zoneinfo/$TIMEZONE"
  actual_target="$(readlink -f /etc/localtime)"

  [[ "$actual_target" == "$expected_target" ]] ||
    die "/etc/localtime does not point to the expected timezone."
}

validate_adjtime() {
  [[ -s /etc/adjtime ]] ||
    die "/etc/adjtime was not created."

  grep -Fxq 'UTC' /etc/adjtime ||
    die "The hardware clock is not configured to use UTC."
}

validate_date_output() {
  local configured_zone

  configured_zone="$(
    date +%Z
  )"

  [[ -n "$configured_zone" ]] ||
    die "Unable to determine the configured timezone abbreviation."
}

show_result() {
  printf '\nTime configuration completed successfully.\n\n'

  printf 'Timezone link:\n'
  printf '  /etc/localtime -> %s\n' "$(readlink /etc/localtime)"

  printf '\nCurrent system time:\n'
  printf '  %s\n' "$(date --iso-8601=seconds)"

  printf '\nHardware clock policy:\n'
  sed 's/^/  /' /etc/adjtime

  printf '\nNext step:\n'
  printf '  13-configure-localization\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_timezone
  show_plan
  confirm_configuration
  configure_timezone
  configure_hardware_clock
  validate_localtime
  validate_adjtime
  validate_date_output
  show_result
}

main "$@"
```
