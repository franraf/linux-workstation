```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly CONFIG_DIRECTORY="/etc/systemd/journald.conf.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"
readonly JOURNAL_DIRECTORY="/var/log/journal"
readonly JOURNAL_SERVICE="systemd-journald.service"

readonly STORAGE_MODE="persistent"
readonly SYSTEM_MAX_USE="512M"
readonly RUNTIME_MAX_USE="64M"
readonly MAX_RETENTION="14day"

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

This script configures persistent systemd journal storage.

Configuration file:

  ${CONFIG_FILE}

Managed settings:

  Storage=${STORAGE_MODE}
  SystemMaxUse=${SYSTEM_MAX_USE}
  RuntimeMaxUse=${RUNTIME_MAX_USE}
  MaxRetentionSec=${MAX_RETENTION}
  ForwardToWall=no
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
    journalctl
    mktemp
    stat
    systemctl
    systemd-analyze
    systemd-tmpfiles
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

  systemctl cat "$JOURNAL_SERVICE" >/dev/null 2>&1 ||
    die "${JOURNAL_SERVICE} is unavailable."
}

show_plan() {
  cat <<EOF

Journal configuration
---------------------

Implementation:
  systemd-journald

Storage:
  ${STORAGE_MODE}

Persistent limit:
  ${SYSTEM_MAX_USE}

Runtime limit:
  ${RUNTIME_MAX_USE}

Retention:
  ${MAX_RETENTION}

Forward to wall:
  disabled

Configuration:
  ${CONFIG_FILE}

Persistent directory:
  ${JOURNAL_DIRECTORY}
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType JOURNAL to apply the configuration: '
  read -r confirmation

  [[ "$confirmation" == "JOURNAL" ]] ||
    die "Journal configuration was not authorized."
}

write_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
# Managed by linux-workstation.
# Profile: dell-latitude-e5470

[Journal]
Storage=${STORAGE_MODE}
SystemMaxUse=${SYSTEM_MAX_USE}
RuntimeMaxUse=${RUNTIME_MAX_USE}
MaxRetentionSec=${MAX_RETENTION}
ForwardToWall=no
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
    die "journald configuration file was not created."

  [[ "$(stat -c '%U:%G' "$CONFIG_FILE")" == "root:root" ]] ||
    die "journald configuration ownership is incorrect."

  [[ "$(stat -c '%a' "$CONFIG_FILE")" == "644" ]] ||
    die "journald configuration permissions are incorrect."

  grep -Fxq "Storage=${STORAGE_MODE}" "$CONFIG_FILE" ||
    die "Storage configuration is incorrect."

  grep -Fxq "SystemMaxUse=${SYSTEM_MAX_USE}" "$CONFIG_FILE" ||
    die "SystemMaxUse configuration is incorrect."

  grep -Fxq "RuntimeMaxUse=${RUNTIME_MAX_USE}" "$CONFIG_FILE" ||
    die "RuntimeMaxUse configuration is incorrect."

  grep -Fxq "MaxRetentionSec=${MAX_RETENTION}" "$CONFIG_FILE" ||
    die "MaxRetentionSec configuration is incorrect."

  grep -Fxq "ForwardToWall=no" "$CONFIG_FILE" ||
    die "ForwardToWall configuration is incorrect."
}

validate_effective_configuration() {
  local effective_config

  effective_config="$(
    systemd-analyze cat-config systemd/journald.conf
  )"

  grep -Fq "Storage=${STORAGE_MODE}" <<<"$effective_config" ||
    die "Storage configuration is not visible to systemd."

  grep -Fq "SystemMaxUse=${SYSTEM_MAX_USE}" <<<"$effective_config" ||
    die "SystemMaxUse configuration is not visible to systemd."

  grep -Fq "RuntimeMaxUse=${RUNTIME_MAX_USE}" <<<"$effective_config" ||
    die "RuntimeMaxUse configuration is not visible to systemd."

  grep -Fq "MaxRetentionSec=${MAX_RETENTION}" <<<"$effective_config" ||
    die "MaxRetentionSec configuration is not visible to systemd."
}

prepare_persistent_storage() {
  log "Preparing persistent journal storage."

  install \
    --directory \
    --owner root \
    --group systemd-journal \
    --mode 2755 \
    "$JOURNAL_DIRECTORY"

  systemd-tmpfiles \
    --create \
    --prefix "$JOURNAL_DIRECTORY"
}

restart_journald() {
  log "Restarting systemd-journald."

  systemctl restart "$JOURNAL_SERVICE"

  systemctl is-active --quiet "$JOURNAL_SERVICE" ||
    die "${JOURNAL_SERVICE} did not return to the active state."
}

flush_journal() {
  log "Flushing runtime journal data to persistent storage."

  journalctl --flush
}

validate_persistent_storage() {
  [[ -d "$JOURNAL_DIRECTORY" ]] ||
    die "Persistent journal directory does not exist."

  [[ "$(stat -c '%G' "$JOURNAL_DIRECTORY")" == "systemd-journal" ]] ||
    warn "Unexpected group ownership for $JOURNAL_DIRECTORY."

  journalctl \
    --directory "$JOURNAL_DIRECTORY" \
    --no-pager \
    --lines=1 >/dev/null 2>&1 ||
    die "Persistent journal storage could not be read."
}

validate_journal() {
  journalctl --verify >/dev/null ||
    die "Journal verification failed."
}

show_result() {
  printf '\nJournald configured successfully.\n\n'

  printf 'Configuration:\n'
  printf '  %s\n' "$CONFIG_FILE"

  printf '\nPersistent storage:\n'
  printf '  %s\n' "$JOURNAL_DIRECTORY"

  printf '\nCurrent disk usage:\n'
  journalctl --disk-usage |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  07-configure-zram\n'
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
  validate_effective_configuration
  prepare_persistent_storage
  restart_journald
  flush_journal
  validate_persistent_storage
  validate_journal
  show_result
}

main "$@"
```
