#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly CONFIG_DIRECTORY="/etc/systemd/timesyncd.conf.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"

readonly TIME_SYNC_SERVICE="systemd-timesyncd.service"

readonly PRIMARY_NTP="time.cloudflare.com"
readonly FALLBACK_NTP="0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org"

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
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
  sudo ./$SCRIPT_NAME

This script configures system time synchronization using systemd-timesyncd.

Configuration file:

  ${CONFIG_FILE}

Primary NTP:
  ${PRIMARY_NTP}

Fallback NTP:
  ${FALLBACK_NTP}
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    install
    mktemp
    systemctl
    timedatectl
    sed
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
    die "This script must run on Arch Linux."

  [[ -d /run/systemd/system ]] ||
    die "systemd is not running as PID 1."
}

validate_service_available() {
  systemctl cat "$TIME_SYNC_SERVICE" >/dev/null 2>&1 ||
    die "${TIME_SYNC_SERVICE} is unavailable."
}

show_plan() {
  cat <<EOF

Time synchronization
--------------------

Implementation:
  systemd-timesyncd

Configuration:
  ${CONFIG_FILE}

Primary NTP:
  ${PRIMARY_NTP}

Fallback NTP:
  ${FALLBACK_NTP}

Service:
  ${TIME_SYNC_SERVICE}
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType TIMESYNC to apply the configuration: '
  read -r confirmation

  [[ "$confirmation" == "TIMESYNC" ]] ||
    die "Time synchronization configuration was not authorized."
}

write_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
# Managed by linux-workstation.
# Profile: dell-latitude-e5470

[Time]
NTP=${PRIMARY_NTP}
FallbackNTP=${FALLBACK_NTP}
EOF

  install \
    --directory \
    --owner root \
    --group root \
    --mode 0755 \
    "$CONFIG_DIRECTORY"

  install \
    --owner root \
    --group root \
    --mode 0644 \
    "$temporary_file" \
    "$CONFIG_FILE"

  rm -f "$temporary_file"
  trap - RETURN
}

enable_service() {
  log "Enabling ${TIME_SYNC_SERVICE}."

  systemctl enable "$TIME_SYNC_SERVICE"
}

restart_service() {
  log "Restarting ${TIME_SYNC_SERVICE}."

  systemctl restart "$TIME_SYNC_SERVICE"
}

enable_ntp() {
  log "Enabling network time synchronization."

  timedatectl set-ntp true
}

validate_configuration_file() {
  [[ -s "$CONFIG_FILE" ]] ||
    die "Time synchronization configuration was not created."

  grep -Fxq "NTP=${PRIMARY_NTP}" "$CONFIG_FILE" ||
    die "Primary NTP configuration is incorrect."

  grep -Fxq "FallbackNTP=${FALLBACK_NTP}" "$CONFIG_FILE" ||
    die "Fallback NTP configuration is incorrect."
}

validate_service_state() {
  systemctl is-enabled --quiet "$TIME_SYNC_SERVICE" ||
    die "${TIME_SYNC_SERVICE} is not enabled."

  systemctl is-active --quiet "$TIME_SYNC_SERVICE" ||
    die "${TIME_SYNC_SERVICE} is not active."
}

validate_ntp_enabled() {
  local ntp_state

  ntp_state="$(
    timedatectl show \
      --property=NTP \
      --value
  )"

  [[ "$ntp_state" == "yes" ]] ||
    die "Network time synchronization is not enabled."
}

validate_synchronization_state() {
  local synchronized

  synchronized="$(
    timedatectl show \
      --property=NTPSynchronized \
      --value
  )"

  if [[ "$synchronized" != "yes" ]]; then
    warn "The system is not synchronized yet."
    warn "This may be normal immediately after enabling timesyncd."
  fi
}

show_result() {
  printf '\nTime synchronization configured successfully.\n\n'

  printf 'Service:\n'
  printf '  %s\n' "$TIME_SYNC_SERVICE"

  printf '\nConfiguration:\n'
  printf '  %s\n' "$CONFIG_FILE"

  printf '\nStatus:\n'
  timedatectl status |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  06-configure-journald\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_service_available
  show_plan
  confirm_configuration
  write_configuration
  enable_service
  enable_ntp
  restart_service
  validate_configuration_file
  validate_service_state
  validate_ntp_enabled
  validate_synchronization_state
  show_result
}

main "$@"
