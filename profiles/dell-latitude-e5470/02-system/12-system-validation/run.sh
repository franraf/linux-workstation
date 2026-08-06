#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly PACMAN_CONFIG="/etc/pacman.conf"
readonly JOURNAL_CONFIG="/etc/systemd/journald.conf.d/10-linux-workstation.conf"
readonly ZRAM_CONFIG="/etc/systemd/zram-generator.conf.d/10-linux-workstation.conf"
readonly SSH_CONFIG="/etc/ssh/sshd_config.d/10-linux-workstation.conf"

readonly REQUIRED_PACKAGES=(
  base
  linux
  linux-firmware
  intel-ucode
  btrfs-progs
  cryptsetup
  networkmanager
  bluez
  bluez-utils
  openssh
  zram-generator
  sudo
  curl
  wget
  rsync
  zip
  unzip
  bash-completion
  htop
  lsof
  tree
  lm_sensors
)

readonly REQUIRED_ENABLED_UNITS=(
  NetworkManager.service
  bluetooth.service
  sshd.service
  systemd-timesyncd.service
  fstrim.timer
)

readonly REQUIRED_ACTIVE_UNITS=(
  NetworkManager.service
  sshd.service
  systemd-timesyncd.service
  fstrim.timer
)

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  printf '[PASS] %s\n' "$*"
  ((PASS_COUNT += 1))
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
  ((WARN_COUNT += 1))
}

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  ((FAIL_COUNT += 1))
}

section() {
  printf '\n== %s ==\n\n' "$*"
}

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

This script validates the completed 02-system phase.

It does not modify system state.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help | -h)
        usage
        exit 0
        ;;

      *)
        printf '[ERROR] Unknown argument: %s\n' "$1" >&2
        exit 1
        ;;
    esac
  done
}

require_commands() {
  local commands=(
    awk
    bootctl
    findmnt
    fstrim
    grep
    journalctl
    locale
    lsblk
    pacman
    sshd
    swapon
    systemctl
    timedatectl
    uname
    zramctl
    sed
    xargs
    systemd-analyze
  )

  local command_name

  for command_name in "${commands[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
      pass "Command available: $command_name"
    else
      fail "Required command unavailable: $command_name"
    fi
  done
}

validate_execution_context() {
  section "Execution context"

  if [[ -f /etc/os-release ]] &&
     grep -q '^ID=arch$' /etc/os-release; then
    pass "Operating system is Arch Linux"
  else
    fail "Operating system is not identified as Arch Linux"
  fi

  if [[ -d /run/systemd/system ]]; then
    pass "systemd is running"
  else
    fail "systemd is not running"
  fi

  if [[ -s /etc/fstab ]]; then
    pass "/etc/fstab exists and is not empty"
  else
    fail "/etc/fstab is missing or empty"
  fi
}

validate_system_update() {
  section "System update"

  if pacman -Dk >/dev/null 2>&1; then
    pass "Pacman database is consistent"
  else
    fail "Pacman database consistency check failed"
  fi

  if pacman -Syu --print-format '%n %v' 2>/dev/null |
     grep -q .; then
    warn "Package updates are currently available"
  else
    pass "No pending package upgrade detected"
  fi
}

validate_pacman() {
  section "Pacman"

  if [[ ! -f "$PACMAN_CONFIG" ]]; then
    fail "pacman.conf is missing"
    return
  fi

  local expected_patterns=(
    '^Color[[:space:]]*$'
    '^VerbosePkgLists[[:space:]]*$'
    '^CheckSpace[[:space:]]*$'
    '^ParallelDownloads[[:space:]]*=[[:space:]]*5[[:space:]]*$'
  )

  local pattern

  for pattern in "${expected_patterns[@]}"; do
    if grep -Eq "$pattern" "$PACMAN_CONFIG"; then
      pass "Pacman option matched: $pattern"
    else
      fail "Pacman option missing: $pattern"
    fi
  done
}

validate_microcode() {
  section "Microcode"

  if pacman -Q intel-ucode >/dev/null 2>&1; then
    pass "intel-ucode is installed"
  else
    fail "intel-ucode is not installed"
  fi

  if [[ -s /boot/intel-ucode.img ]]; then
    pass "Intel microcode image exists"
  else
    fail "/boot/intel-ucode.img is missing"
  fi

  if journalctl -b -k 2>/dev/null | grep -Ei 'microcode:.*(Current revision|updated|revision)'; then
    pass "Boot journal contains microcode information"
  else
    warn "No microcode message found in current boot journal"
  fi
}

validate_systemd() {
  section "systemd"

  if systemd-analyze cat-config systemd/system.conf \
    >/dev/null 2>&1; then
    pass "systemd manager configuration is parseable"
  else
    fail "systemd manager configuration could not be parsed"
  fi
}

validate_time_sync() {
  section "Time synchronization"

  if systemctl is-enabled --quiet systemd-timesyncd.service; then
    pass "systemd-timesyncd is enabled"
  else
    fail "systemd-timesyncd is not enabled"
  fi

  if systemctl is-active --quiet systemd-timesyncd.service; then
    pass "systemd-timesyncd is active"
  else
    fail "systemd-timesyncd is not active"
  fi

  local ntp_enabled
  local synchronized

  ntp_enabled="$(
    timedatectl show \
      --property=NTP \
      --value 2>/dev/null || true
  )"

  synchronized="$(
    timedatectl show \
      --property=NTPSynchronized \
      --value 2>/dev/null || true
  )"

  if [[ "$ntp_enabled" == "yes" ]]; then
    pass "Network time synchronization is enabled"
  else
    fail "Network time synchronization is disabled"
  fi

  if [[ "$synchronized" == "yes" ]]; then
    pass "System clock is synchronized"
  else
    warn "System clock is not currently synchronized"
  fi
}

validate_journald() {
  section "Journald"

  if [[ -s "$JOURNAL_CONFIG" ]]; then
    pass "Journald profile configuration exists"
  else
    fail "Journald profile configuration is missing"
  fi

  if [[ -d /var/log/journal ]]; then
    pass "Persistent journal directory exists"
  else
    fail "/var/log/journal does not exist"
  fi

  if journalctl --verify >/dev/null 2>&1; then
    pass "Journal verification succeeded"
  else
    fail "Journal verification failed"
  fi
}

validate_zram() {
  section "ZRAM"

  if pacman -Q zram-generator >/dev/null 2>&1; then
    pass "zram-generator is installed"
  else
    fail "zram-generator is not installed"
  fi

  if [[ -s "$ZRAM_CONFIG" ]]; then
    pass "ZRAM profile configuration exists"
  else
    fail "ZRAM profile configuration is missing"
  fi

  if [[ -b /dev/zram0 ]]; then
    pass "/dev/zram0 exists"
  else
    fail "/dev/zram0 does not exist"
    return
  fi

  if swapon --noheadings --show=NAME --raw |
     grep -Fxq /dev/zram0; then
    pass "/dev/zram0 is active as swap"
  else
    fail "/dev/zram0 is not active as swap"
  fi

  if zramctl /dev/zram0 >/dev/null 2>&1; then
    pass "ZRAM device can be inspected"
  else
    fail "ZRAM device inspection failed"
  fi
}

validate_trim() {
  section "TRIM"

  if systemctl is-enabled --quiet fstrim.timer; then
    pass "fstrim.timer is enabled"
  else
    fail "fstrim.timer is not enabled"
  fi

  if systemctl is-active --quiet fstrim.timer; then
    pass "fstrim.timer is active"
  else
    fail "fstrim.timer is not active"
  fi

  local root_device
  local discard_max

  root_device="$(
    findmnt -no SOURCE / |
      sed 's/\[.*\]$//' |
      xargs
  )"

  discard_max="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output DISC-MAX \
      "$root_device" 2>/dev/null |
      xargs
  )"

  if [[ -n "$discard_max" &&
        "$discard_max" != "0B" &&
        "$discard_max" != "0" ]]; then
    pass "Discard is available through the root block device"
  else
    fail "Discard is not available through the root block device"
  fi
}

validate_services() {
  section "Base services"

  local unit

  for unit in "${REQUIRED_ENABLED_UNITS[@]}"; do
    if systemctl is-enabled --quiet "$unit"; then
      pass "$unit is enabled"
    else
      fail "$unit is not enabled"
    fi
  done

  for unit in "${REQUIRED_ACTIVE_UNITS[@]}"; do
    if systemctl is-active --quiet "$unit"; then
      pass "$unit is active"
    else
      fail "$unit is not active"
    fi
  done

  if [[ -d /sys/class/bluetooth ]]; then
    if systemctl is-active --quiet bluetooth.service; then
      pass "bluetooth.service is active"
    else
      warn "Bluetooth hardware exists but bluetooth.service is not active"
    fi
  else
    warn "Bluetooth controller is not currently visible"
  fi
}

validate_ssh() {
  section "OpenSSH"

  if [[ -s "$SSH_CONFIG" ]]; then
    pass "SSH profile configuration exists"
  else
    fail "SSH profile configuration is missing"
  fi

  if sshd -t >/dev/null 2>&1; then
    pass "sshd configuration syntax is valid"
  else
    fail "sshd configuration syntax is invalid"
    return
  fi

  local effective_config

  effective_config="$(sshd -T 2>/dev/null)"

  local expected=(
    'permitrootlogin no'
    'pubkeyauthentication yes'
    'passwordauthentication yes'
    'permitemptypasswords no'
    'kbdinteractiveauthentication no'
    'x11forwarding no'
  )

  local setting
  local option
  local expected_value

  for setting in "${expected[@]}"; do
    option="${setting%% *}"
    expected_value="${setting#* }"

    if awk \
      -v option="$option" \
      -v expected_value="$expected_value" '
        tolower($1) == tolower(option) &&
	tolower($2) == tolower(expected_value) {
	  found = 1
	  exit
        }

        END {
	  exit(found ? 0 : 1)
	}
      ' <<<"$effective_config"; then
      pass "SSH effective setting: $setting"
    else
      fail "SSH effective setting missing: $setting"
    fi
  done
}

validate_packages() {
  section "Packages"

  local package

  for package in "${REQUIRED_PACKAGES[@]}"; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      pass "Installed package: $package"
    else
      fail "Missing package: $package"
    fi
  done
}

validate_filesystems() {
  section "Filesystem"

  local expected=(
    "/:btrfs"
    "/boot:vfat"
    "/home:btrfs"
    "/var:btrfs"
    "/var/log:btrfs"
    "/var/cache:btrfs"
    "/var/cache/pacman/pkg:btrfs"
    "/var/lib/docker:btrfs"
    "/.snapshots:btrfs"
  )

  local mapping
  local mountpoint_path
  local filesystem_type
  local actual_type

  for mapping in "${expected[@]}"; do
    mountpoint_path="${mapping%%:*}"
    filesystem_type="${mapping#*:}"

    actual_type="$(
      findmnt \
        --noheadings \
        --output FSTYPE \
        --target "$mountpoint_path" 2>/dev/null |
        xargs
    )"

    if [[ "$actual_type" == "$filesystem_type" ]]; then
      pass "$mountpoint_path uses $filesystem_type"
    else
      fail "$mountpoint_path expected $filesystem_type, found ${actual_type:-none}"
    fi
  done
}

validate_boot() {
  section "Boot"

  if bootctl is-installed >/dev/null 2>&1; then
    pass "systemd-boot is installed"
  else
    fail "systemd-boot is not installed"
  fi

  if grep -Rqs \
    'rd\.luks\.options=.*=discard' \
    /boot/loader/entries; then
    pass "LUKS discard option is present in boot entries"
  else
    fail "LUKS discard option is missing from boot entries"
  fi
}

validate_failed_units() {
  section "Failed units"

  local failed_units

  failed_units="$(
    systemctl \
      --failed \
      --no-legend \
      --plain 2>/dev/null || true
  )"

  if [[ -z "$failed_units" ]]; then
    pass "No failed systemd units"
  else
    fail "Failed systemd units detected"
    printf '%s\n' "$failed_units" >&2
  fi
}

show_summary() {
  printf '\n========================================\n'
  printf 'System validation summary\n'
  printf '========================================\n\n'

  printf 'Passed:   %d\n' "$PASS_COUNT"
  printf 'Warnings: %d\n' "$WARN_COUNT"
  printf 'Failed:   %d\n' "$FAIL_COUNT"

  if ((FAIL_COUNT == 0)); then
    printf '\nSystem phase validation completed successfully.\n'
    printf '\nNext phase:\n'
    printf '  03-desktop\n'
    return 0
  fi

  printf '\nSystem phase validation failed.\n'
  printf 'Resolve all failed checks before continuing to 03-desktop.\n'

  return 1
}

main() {
  parse_arguments "$@"

  section "Required commands"
  require_commands

  validate_execution_context
  validate_system_update
  validate_pacman
  validate_microcode
  validate_systemd
  validate_time_sync
  validate_journald
  validate_zram
  validate_trim
  validate_services
  validate_ssh
  validate_packages
  validate_filesystems
  validate_boot
  validate_failed_units
  show_summary
}

main "$@"
