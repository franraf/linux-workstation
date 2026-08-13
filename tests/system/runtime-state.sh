#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() { printf '[PASS] %s\n' "$*"; ((PASS_COUNT += 1)); }
warn() { printf '[WARN] %s\n' "$*" >&2; ((WARN_COUNT += 1)); }
fail() { printf '[FAIL] %s\n' "$*" >&2; ((FAIL_COUNT += 1)); }
section() { printf '\n== %s ==\n\n' "$*"; }

check_package_file() {
  local file="$1"
  local package
  while IFS= read -r package; do
    package="${package%%#*}"
    package="${package//[[:space:]]/}"
    [[ -n "$package" ]] || continue
    if pacman -Q "$package" >/dev/null 2>&1; then pass "Installed package: $package"; else fail "Missing package: $package"; fi
  done <"$file"
}

check_file_matches() {
  local source="$1"
  local destination="$2"
  if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
    pass "Configuration matches canonical source: $destination"
  else
    fail "Configuration differs from canonical source: $destination"
  fi
}

section "Execution context"
[[ -f /etc/os-release ]] && grep -q '^ID=arch$' /etc/os-release && pass "Operating system is Arch Linux" || fail "Operating system is not Arch Linux"
[[ -d /run/systemd/system ]] && pass "systemd is running" || fail "systemd is not running"

section "Packages"
check_package_file "${REPO_ROOT}/packages/system/base-workstation.txt"
check_package_file "${REPO_ROOT}/packages/system/services.txt"
pacman -Q intel-ucode >/dev/null 2>&1 && pass "intel-ucode is installed" || fail "intel-ucode is missing"

section "Canonical configuration"
check_file_matches "${REPO_ROOT}/system/systemd/10-linux-workstation.conf" /etc/systemd/system.conf.d/10-linux-workstation.conf
check_file_matches "${REPO_ROOT}/system/systemd/timesyncd/10-linux-workstation.conf" /etc/systemd/timesyncd.conf.d/10-linux-workstation.conf
check_file_matches "${REPO_ROOT}/system/systemd/journald/10-linux-workstation.conf" /etc/systemd/journald.conf.d/10-linux-workstation.conf
check_file_matches "${REPO_ROOT}/system/systemd/zram/10-linux-workstation.conf" /etc/systemd/zram-generator.conf.d/10-linux-workstation.conf
check_file_matches "${REPO_ROOT}/system/openssh/10-linux-workstation.conf" /etc/ssh/sshd_config.d/10-linux-workstation.conf

section "Services"
for unit in NetworkManager.service bluetooth.service sshd.service systemd-timesyncd.service fstrim.timer; do
  systemctl is-enabled --quiet "$unit" && pass "$unit is enabled" || fail "$unit is not enabled"
done
for unit in NetworkManager.service sshd.service systemd-timesyncd.service fstrim.timer; do
  systemctl is-active --quiet "$unit" && pass "$unit is active" || fail "$unit is not active"
done
if [[ -d /sys/class/bluetooth ]]; then
  systemctl is-active --quiet bluetooth.service && pass "bluetooth.service is active" || warn "Bluetooth hardware exists but bluetooth.service is not active"
else
  warn "Bluetooth controller is not currently visible"
fi

section "Runtime capabilities"
[[ -s /boot/intel-ucode.img ]] && pass "Intel microcode image exists" || fail "Intel microcode image is missing"
[[ -b /dev/zram0 ]] && pass "/dev/zram0 exists" || fail "/dev/zram0 does not exist"
if swapon --noheadings --show=NAME --raw | awk '$1 == "/dev/zram0" { found=1 } END { exit(found ? 0 : 1) }'; then pass "/dev/zram0 is active as swap"; else fail "/dev/zram0 is not active as swap"; fi
[[ -d /var/log/journal ]] && pass "Persistent journal directory exists" || fail "Persistent journal directory is missing"
sshd -t >/dev/null 2>&1 && pass "sshd configuration syntax is valid" || fail "sshd configuration syntax is invalid"

section "Filesystem and boot"
while IFS=$'\t' read -r subvolume mountpoint options; do
  [[ -n "$subvolume" && "$subvolume" != \#* ]] || continue
  actual="$(findmnt --noheadings --output FSTYPE --target "$mountpoint" 2>/dev/null | xargs)"
  [[ "$actual" == "btrfs" ]] && pass "$mountpoint uses btrfs" || fail "$mountpoint expected btrfs, found ${actual:-none}"
done <"${REPO_ROOT}/system/storage/btrfs-layout.tsv"
findmnt --noheadings --output FSTYPE --target /boot | grep -q '^vfat$' && pass "/boot uses vfat" || fail "/boot is not vfat"
bootctl is-installed >/dev/null 2>&1 && pass "systemd-boot is installed" || fail "systemd-boot is not installed"

section "Failed units"
failed_units="$(systemctl --failed --no-legend --plain 2>/dev/null || true)"
[[ -z "$failed_units" ]] && pass "No failed systemd units" || { fail "Failed systemd units detected"; printf '%s\n' "$failed_units" >&2; }

printf '\n========================================\nSystem validation summary\n========================================\n\n'
printf 'Passed:   %d\nWarnings: %d\nFailed:   %d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
((FAIL_COUNT == 0)) || exit 1
printf '\nSystem runtime validation completed successfully.\n'
