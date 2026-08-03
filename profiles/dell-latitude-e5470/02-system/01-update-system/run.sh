```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

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

This script synchronizes package databases, performs a full system
upgrade and validates the resulting package state.

This script must run on the installed Arch Linux system.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    pacman
    systemctl
    findmnt
    awk
    uname
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

  [[ -s /etc/fstab ]] ||
    die "The installed-system fstab is missing or empty."

  [[ "$(findmnt -no SOURCE /)" != "overlay" ]] ||
    die "Refusing to run inside an overlay/live environment."
}

validate_package_database() {
  [[ -d /var/lib/pacman/local ]] ||
    die "Pacman local database is unavailable."

  pacman -Q >/dev/null ||
    die "Pacman package database could not be read."
}

show_plan() {
  cat <<EOF

System update
-------------

Package manager: pacman
Strategy:        full system upgrade
Database sync:   enabled

Operation:

  pacman -Syu

No partial upgrade will be performed.
EOF
}

confirm_update() {
  local confirmation

  printf '\nType UPDATE to perform the full system upgrade: '
  read -r confirmation

  [[ "$confirmation" == "UPDATE" ]] ||
    die "System update was not authorized."
}

update_system() {
  log "Synchronizing package databases and upgrading the system."

  pacman \
    --sync \
    --refresh \
    --sysupgrade
}

validate_package_integrity() {
  log "Validating installed package database."

  pacman -Dk
}

validate_pending_updates() {
  log "Refreshing package databases for final validation."

  pacman \
    --sync \
    --refresh \
    --print-format '%n %v' \
    --sysupgrade |
    grep -q . &&
    die "Package updates remain after the system upgrade."

  true
}

validate_failed_services() {
  local failed_units

  failed_units="$(
    systemctl \
      --failed \
      --no-legend \
      --plain 2>/dev/null || true
  )"

  if [[ -n "$failed_units" ]]; then
    warn "Failed systemd units were detected:"
    printf '%s\n' "$failed_units" >&2
  fi
}

validate_reboot_recommended() {
  local running_kernel
  local installed_kernel

  running_kernel="$(uname -r)"

  installed_kernel="$(
    pacman -Q linux |
      awk '{print $2}'
  )"

  printf '\nKernel state:\n'
  printf '  Running:   %s\n' "$running_kernel"
  printf '  Installed: %s\n' "$installed_kernel"

  if [[ -e /usr/lib/modules/"$running_kernel" ]]; then
    printf '  Reboot:    not required by kernel removal\n'
  else
    warn "Running kernel no longer exists in /usr/lib/modules."
    warn "A reboot is recommended before continuing."
  fi
}

show_result() {
  printf '\nSystem update completed successfully.\n\n'

  printf 'Package database:\n'
  printf '  valid\n'

  printf '\nPending updates:\n'
  printf '  none\n'

  printf '\nNext step:\n'
  printf '  02-configure-pacman\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_package_database
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
```
