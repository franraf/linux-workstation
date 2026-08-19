#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

passed=0
warnings=0
failed=0

pass() {
  printf '[PASS] %s\n' "$*"
  ((passed += 1))
}
warn_check() {
  printf '[WARN] %s\n' "$*"
  ((warnings += 1))
}
fail_check() {
  printf '[FAIL] %s\n' "$*"
  ((failed += 1))
}

check_failed_units() {
  local units
  units="$(systemctl --failed --no-legend --plain 2>/dev/null || true)"
  if [[ -z "$units" ]]; then
    pass "No failed systemd units"
  else
    fail_check "Failed systemd units detected"
    printf '%s\n' "$units" | sed 's/^/       /'
  fi
}

check_root_space() {
  local used
  used="$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')"
  if ((used >= 95)); then
    fail_check "Root filesystem usage is ${used}% (threshold: 95%)"
  elif ((used >= 85)); then
    warn_check "Root filesystem usage is ${used}% (warning threshold: 85%)"
  else
    pass "Root filesystem usage is ${used}%"
  fi
}

check_btrfs() {
  local fs_type
  fs_type="$(findmnt -n -o FSTYPE / 2>/dev/null || true)"
  if [[ "$fs_type" != btrfs ]]; then
    fail_check "Root filesystem is ${fs_type:-unknown}, expected btrfs"
    return
  fi
  pass "Root filesystem is Btrfs"

  if btrfs device stats / >/tmp/linux-workstation-btrfs-stats.$$ 2>/dev/null; then
    if awk -F' ' '$NF != 0 {bad=1} END {exit bad ? 0 : 1}' /tmp/linux-workstation-btrfs-stats.$$; then
      warn_check "Btrfs device statistics contain non-zero error counters"
      sed 's/^/       /' /tmp/linux-workstation-btrfs-stats.$$
    else
      pass "Btrfs device error counters are zero"
    fi
  else
    warn_check "Btrfs device statistics could not be read"
  fi
  rm -f /tmp/linux-workstation-btrfs-stats.$$
}

check_network() {
  if ip route show default | grep -q '^default '; then
    pass "Default network route exists"
  else
    fail_check "No default network route exists"
  fi
}

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    warn_check "Docker command is not installed"
    return
  fi
  if systemctl is-active --quiet docker.service; then
    pass "docker.service is active"
  else
    warn_check "Docker is installed but docker.service is not active"
  fi
}

check_pacman_database() {
  if pacman -Dk >/dev/null 2>&1; then
    pass "Pacman local database consistency check passed"
  else
    fail_check "Pacman local database consistency check failed"
  fi
}

check_boot_errors() {
  local count
  count="$(journalctl -b -p err --no-pager 2>/dev/null | awk 'NF {count++} END {print count+0}')"
  if ((count == 0)); then
    pass "No error-priority journal entries in current boot"
  else
    warn_check "Current boot contains ${count} error-priority journal entries; review with: journalctl -b -p err"
  fi
}

show_summary() {
  printf '\n========================================\n'
  printf 'Operations health-check summary\n'
  printf '========================================\n\n'
  printf 'Passed:   %d\n' "$passed"
  printf 'Warnings: %d\n' "$warnings"
  printf 'Failed:   %d\n' "$failed"
}

main() {
  require_root
  require_commands awk btrfs df findmnt grep ip journalctl pacman sed systemctl
  require_arch_systemd

  printf '\nWorkstation health checks\n-------------------------\n\n'
  check_failed_units
  check_root_space
  check_btrfs
  check_network
  check_docker
  check_pacman_database
  check_boot_errors
  show_summary

  ((failed == 0)) || exit 1
}

main "$@"
