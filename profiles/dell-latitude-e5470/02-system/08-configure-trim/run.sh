#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly TRIM_TIMER="fstrim.timer"
readonly TRIM_SERVICE="fstrim.service"
readonly ROOT_MOUNT="/"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  printf 'Usage:\n  sudo ./%s\n\nEnables periodic SSD trimming through %s.\n' "$SCRIPT_NAME" "$TRIM_TIMER"
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

discover_root_device() {
  findmnt --noheadings --output SOURCE --target "$ROOT_MOUNT" | sed 's/\[.*\]$//' | xargs
}

confirm_configuration() {
  local confirmation
  printf '\nType TRIM to enable periodic trimming: '
  read -r confirmation
  [[ "$confirmation" == "TRIM" ]] || die "TRIM configuration was not authorized."
}

main() {
  require_root
  require_commands findmnt fstrim lsblk sed systemctl xargs
  require_arch_systemd
  parse_arguments "$@"

  systemctl cat "$TRIM_TIMER" >/dev/null 2>&1 || die "${TRIM_TIMER} is unavailable."
  systemctl cat "$TRIM_SERVICE" >/dev/null 2>&1 || die "${TRIM_SERVICE} is unavailable."

  local filesystem_type root_device discard_max root_options output
  filesystem_type="$(findmnt --noheadings --output FSTYPE --target "$ROOT_MOUNT" | xargs)"
  [[ "$filesystem_type" == "btrfs" ]] || die "Expected Btrfs root filesystem, found: $filesystem_type"

  root_device="$(discover_root_device)"
  [[ -n "$root_device" ]] || die "Unable to determine the root block device."
  discard_max="$(lsblk --noheadings --nodeps --output DISC-MAX "$root_device" | xargs)"
  [[ -n "$discard_max" && "$discard_max" != "0B" && "$discard_max" != "0" ]] || die "Discard is not available through the current root device: $root_device"

  root_options="$(findmnt --noheadings --output OPTIONS --target "$ROOT_MOUNT" | xargs)"
  if [[ ",${root_options}," == *",discard,"* || ",${root_options}," == *",discard=async,"* || ",${root_options}," == *",discard=sync,"* ]]; then
    log_warn "Continuous Btrfs discard is enabled; the profile intends periodic fstrim."
  fi

  printf '\nPeriodic TRIM\n-------------\n\nRoot device:\n  %s\n\nTimer:\n  %s\n' "$root_device" "$TRIM_TIMER"
  confirm_configuration

  if ! output="$(fstrim --verbose "$ROOT_MOUNT" 2>&1)"; then
    printf '%s\n' "$output" >&2
    die "TRIM test failed on the root filesystem."
  fi
  printf '%s\n' "$output"

  systemctl enable "$TRIM_TIMER"
  systemctl start "$TRIM_TIMER"
  systemctl is-enabled --quiet "$TRIM_TIMER" || die "${TRIM_TIMER} is not enabled."
  systemctl is-active --quiet "$TRIM_TIMER" || die "${TRIM_TIMER} is not active."

  printf '\nPeriodic TRIM configured successfully.\n\nNext step:\n  09-configure-system-services\n'
}

main "$@"
