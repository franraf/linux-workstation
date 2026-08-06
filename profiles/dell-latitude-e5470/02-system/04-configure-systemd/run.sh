#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly CONFIG_DIRECTORY="/etc/systemd/system.conf.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"

readonly DEFAULT_TIMEOUT_START="90s"
readonly DEFAULT_TIMEOUT_STOP="90s"
readonly DEFAULT_TIMEOUT_ABORT="90s"
readonly DEFAULT_RUNTIME_WATCHDOG="0"
readonly DEFAULT_REBOOT_WATCHDOG="10min"

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
  sudo ./$SCRIPT_NAME

This script configures global systemd manager defaults.

Configuration file:

  ${CONFIG_FILE}

Managed settings:

  DefaultTimeoutStartSec=${DEFAULT_TIMEOUT_START}
  DefaultTimeoutStopSec=${DEFAULT_TIMEOUT_STOP}
  DefaultTimeoutAbortSec=${DEFAULT_TIMEOUT_ABORT}
  RuntimeWatchdogSec=${DEFAULT_RUNTIME_WATCHDOG}
  RebootWatchdogSec=${DEFAULT_REBOOT_WATCHDOG}
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
    systemd-analyze
    systemctl
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

show_plan() {
  cat <<EOF

systemd configuration
---------------------

Configuration file:
  ${CONFIG_FILE}

Settings:
  DefaultTimeoutStartSec=${DEFAULT_TIMEOUT_START}
  DefaultTimeoutStopSec=${DEFAULT_TIMEOUT_STOP}
  DefaultTimeoutAbortSec=${DEFAULT_TIMEOUT_ABORT}
  RuntimeWatchdogSec=${DEFAULT_RUNTIME_WATCHDOG}
  RebootWatchdogSec=${DEFAULT_REBOOT_WATCHDOG}
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType SYSTEMD to apply the configuration: '
  read -r confirmation

  [[ "$confirmation" == "SYSTEMD" ]] ||
    die "systemd configuration was not authorized."
}

write_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
# Managed by linux-workstation.
# Profile: dell-latitude-e5470

[Manager]
DefaultTimeoutStartSec=${DEFAULT_TIMEOUT_START}
DefaultTimeoutStopSec=${DEFAULT_TIMEOUT_STOP}
DefaultTimeoutAbortSec=${DEFAULT_TIMEOUT_ABORT}
RuntimeWatchdogSec=${DEFAULT_RUNTIME_WATCHDOG}
RebootWatchdogSec=${DEFAULT_REBOOT_WATCHDOG}
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

validate_configuration_file() {
  [[ -s "$CONFIG_FILE" ]] ||
    die "systemd configuration file was not created."

  systemd-analyze \
    cat-config systemd/system.conf >/dev/null ||
    die "systemd could not parse the manager configuration."
}

reload_systemd_manager() {
  log "Reloading systemd manager configuration."

  systemctl daemon-reexec
}

validate_effective_configuration() {
  local effective_config

  effective_config="$(
    systemd-analyze cat-config systemd/system.conf
  )"

  grep -Fq \
    "DefaultTimeoutStartSec=${DEFAULT_TIMEOUT_START}" \
    <<<"$effective_config" ||
    die "DefaultTimeoutStartSec is not effective."

  grep -Fq \
    "DefaultTimeoutStopSec=${DEFAULT_TIMEOUT_STOP}" \
    <<<"$effective_config" ||
    die "DefaultTimeoutStopSec is not effective."

  grep -Fq \
    "DefaultTimeoutAbortSec=${DEFAULT_TIMEOUT_ABORT}" \
    <<<"$effective_config" ||
    die "DefaultTimeoutAbortSec is not effective."

  grep -Fq \
    "RuntimeWatchdogSec=${DEFAULT_RUNTIME_WATCHDOG}" \
    <<<"$effective_config" ||
    die "RuntimeWatchdogSec is not effective."

  grep -Fq \
    "RebootWatchdogSec=${DEFAULT_REBOOT_WATCHDOG}" \
    <<<"$effective_config" ||
    die "RebootWatchdogSec is not effective."
}

show_result() {
  printf '\nsystemd configured successfully.\n\n'

  printf 'Configuration:\n'
  printf '  %s\n' "$CONFIG_FILE"

  printf '\nNext step:\n'
  printf '  05-configure-time-sync\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  show_plan
  confirm_configuration
  write_configuration
  validate_configuration_file
  reload_systemd_manager
  validate_effective_configuration
  show_result
}

main "$@"
