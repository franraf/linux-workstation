#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly TRIM_TIMER="fstrim.timer"
readonly TRIM_SERVICE="fstrim.service"
readonly ROOT_MOUNT="/"

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

This script configures periodic SSD trimming using:

  ${TRIM_TIMER}

The root filesystem must support discard through the complete block
device stack, including the encrypted mapping.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    findmnt
    fstrim
    grep
    lsblk
    systemctl
    sed
    xargs
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

validate_units_available() {
  systemctl cat "$TRIM_TIMER" >/dev/null 2>&1 ||
    die "${TRIM_TIMER} is unavailable."

  systemctl cat "$TRIM_SERVICE" >/dev/null 2>&1 ||
    die "${TRIM_SERVICE} is unavailable."
}

discover_root_device() {
  local root_source

  root_source="$(
    findmnt \
      --noheadings \
      --output SOURCE \
      --target "$ROOT_MOUNT" |
      sed 's/\[.*\]$//' |
      xargs
  )"

  [[ -n "$root_source" ]] ||
    die "Unable to determine the root block device."

  printf '%s\n' "$root_source"
}

validate_root_filesystem() {
  local filesystem_type

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$ROOT_MOUNT" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs root filesystem, found: $filesystem_type"
}

validate_discard_support() {
  local root_device
  local discard_max

  root_device="$(discover_root_device)"

  discard_max="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output DISC-MAX \
      "$root_device" |
      xargs
  )"

  [[ -n "$discard_max" ]] ||
    die "Unable to determine discard capability for $root_device."

  if [[ "$discard_max" == "0B" || "$discard_max" == "0" ]]; then
    cat >&2 <<EOF

[ERROR] Discard is not available through the current root device.

Root device:
  $root_device

Because the root filesystem is encrypted with LUKS, periodic TRIM
requires discard support to be enabled through the dm-crypt mapping.

The boot configuration must enable discard for the encrypted root
before ${TRIM_TIMER} can be used safely and effectively.
EOF

    exit 1
  fi
}

show_plan() {
  local root_device

  root_device="$(discover_root_device)"

  cat <<EOF

Periodic TRIM
-------------

Implementation:
  ${TRIM_TIMER}

Root filesystem:
  ${ROOT_MOUNT}

Root device:
  ${root_device}

Policy:
  periodic TRIM

Continuous mount option:
  discard not configured

Timer:
  systemd-provided weekly schedule
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType TRIM to enable periodic trimming: '
  read -r confirmation

  [[ "$confirmation" == "TRIM" ]] ||
    die "TRIM configuration was not authorized."
}

test_trim() {
  log "Testing TRIM support on the root filesystem."

  local output

  if ! output="$(fstrim --verbose "$ROOT_MOUNT" 2>&1)"; then
    printf '%s\n' "$output" >&2
    die "TRIM test failed on the root filesystem."
  fi

  printf '%s\n' "$output"
}

enable_timer() {
  log "Enabling ${TRIM_TIMER}."

  systemctl enable "$TRIM_TIMER"
}

start_timer() {
  log "Starting ${TRIM_TIMER}."

  systemctl start "$TRIM_TIMER"
}

validate_timer() {
  systemctl is-enabled --quiet "$TRIM_TIMER" ||
    die "${TRIM_TIMER} is not enabled."

  systemctl is-active --quiet "$TRIM_TIMER" ||
    die "${TRIM_TIMER} is not active."
}

validate_schedule() {
  local next_run

  next_run="$(
    systemctl show \
      "$TRIM_TIMER" \
      --property=NextElapseUSecRealtime \
      --value
  )"

  [[ -n "$next_run" ]] ||
    warn "systemd did not report the next scheduled TRIM execution."
}

validate_no_continuous_discard() {
  local root_options

  root_options="$(
    findmnt \
      --noheadings \
      --output OPTIONS \
      --target "$ROOT_MOUNT" |
      xargs
  )"

  if [[ ",${root_options}," == *",discard,"* ]] ||
     [[ ",${root_options}," == *",discard=async,"* ]] ||
     [[ ",${root_options}," == *",discard=sync,"* ]]; then
    warn "Continuous Btrfs discard is enabled."
    warn "The profile intends to use periodic fstrim instead."
  fi
}

show_result() {
  printf '\nPeriodic TRIM configured successfully.\n\n'

  printf 'Timer:\n'
  printf '  %s\n' "$TRIM_TIMER"

  printf '\nState:\n'
  printf '  enabled: %s\n' "$(systemctl is-enabled "$TRIM_TIMER")"
  printf '  active:  %s\n' "$(systemctl is-active "$TRIM_TIMER")"

  printf '\nSchedule:\n'
  systemctl list-timers \
    "$TRIM_TIMER" \
    --no-pager |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  09-configure-system-services\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_units_available
  validate_root_filesystem
  validate_discard_support
  validate_no_continuous_discard
  show_plan
  confirm_configuration
  test_trim
  enable_timer
  start_timer
  validate_timer
  validate_schedule
  show_result
}

main "$@"
