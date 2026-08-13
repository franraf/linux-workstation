#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  printf 'Usage:\n  sudo ./%s\n\nPerforms a full pacman system upgrade.\n' "$SCRIPT_NAME"
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

validate_execution_context() {
  require_arch_systemd
  [[ -s /etc/fstab ]] || die "The installed-system fstab is missing or empty."
  [[ "$(findmnt -no SOURCE /)" != "overlay" ]] || die "Refusing to run inside an overlay/live environment."
  [[ -d /var/lib/pacman/local ]] || die "Pacman local database is unavailable."
  pacman -Q >/dev/null || die "Pacman package database could not be read."
}

show_plan() {
  printf '\nSystem update\n-------------\n\nPackage manager: pacman\nStrategy:        full system upgrade\nOperation:       pacman -Syu\n'
}

confirm_update() {
  local confirmation
  printf '\nType UPDATE to perform the full system upgrade: '
  read -r confirmation
  [[ "$confirmation" == "UPDATE" ]] || die "System update was not authorized."
}

update_system() {
  log_info "Synchronizing package databases and upgrading the system."
  pacman -Syu
}

validate_package_integrity() {
  log_info "Validating installed package database."
  pacman -Dk
}

validate_pending_updates() {
  local pending_updates
  log_info "Checking for pending package upgrades."
  pending_updates="$(pacman -Qu 2>/dev/null || true)"
  [[ -z "$pending_updates" ]] || {
    printf '%s\n' "$pending_updates" >&2
    die "Package updates remain after the system upgrade."
  }
}

validate_failed_services() {
  local failed_units
  failed_units="$(systemctl --failed --no-legend --plain 2>/dev/null || true)"
  if [[ -n "$failed_units" ]]; then
    log_warn "Failed systemd units were detected:"
    printf '%s\n' "$failed_units" >&2
  fi
}

validate_reboot_recommended() {
  local running_kernel
  running_kernel="$(uname -r)"
  printf '\nKernel state:\n  Running: %s\n' "$running_kernel"
  if [[ -e "/usr/lib/modules/${running_kernel}" ]]; then
    printf '  Reboot:  not required by kernel removal\n'
  else
    log_warn "Running kernel no longer exists in /usr/lib/modules; reboot before continuing."
  fi
}

show_result() {
  printf '\nSystem update completed successfully.\n\nNext step:\n  02-configure-pacman\n'
}

main() {
  require_root
  require_commands findmnt pacman systemctl uname
  parse_arguments "$@"
  validate_execution_context
  show_plan
  confirm_update
  update_system
  validate_package_integrity
  validate_pending_updates
  validate_failed_services
  validate_reboot_recommended
  show_result
}

main "$@"
