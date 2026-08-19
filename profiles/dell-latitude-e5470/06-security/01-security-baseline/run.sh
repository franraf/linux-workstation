#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

passed=0
info_count=0
warnings=0
failed=0

pass() { printf '[PASS] %s\n' "$*"; ((passed+=1)); }
info_check() { printf '[INFO] %s\n' "$*"; ((info_count+=1)); }
warn_check() { printf '[WARN] %s\n' "$*"; ((warnings+=1)); }
fail_check() { printf '[FAIL] %s\n' "$*"; ((failed+=1)); }

check_root_encryption() {
  local source type
  source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
  type="$(lsblk -ndo TYPE "$source" 2>/dev/null || true)"

  if [[ "$source" == /dev/mapper/* ]]; then
    pass "Root filesystem is backed by a device-mapper volume: ${source}"
  else
    fail_check "Root filesystem is not backed by the expected encrypted device-mapper volume: ${source:-unknown}"
  fi

  if [[ "$type" == crypt ]]; then
    pass "Root backing device is reported as crypt"
  else
    info_check "Root source type reported as ${type:-unknown}; detailed LUKS inspection follows"
  fi

  if cryptsetup status cryptroot 2>/dev/null | grep -q 'type:[[:space:]]*LUKS2'; then
    pass "cryptroot is active as LUKS2"
  else
    fail_check "cryptroot is not confirmed as active LUKS2"
  fi
}

check_secure_boot() {
  if command -v bootctl >/dev/null 2>&1; then
    local status
    status="$(bootctl status 2>/dev/null || true)"
    if grep -qi 'Secure Boot: enabled' <<<"$status"; then
      pass "Secure Boot is enabled"
    elif grep -qi 'Secure Boot: disabled' <<<"$status"; then
      warn_check "Secure Boot is disabled (planned security work)"
    else
      info_check "Secure Boot state could not be classified from bootctl"
    fi
  else
    info_check "bootctl is unavailable; Secure Boot state not inspected"
  fi
}

check_sshd() {
  if ! command -v sshd >/dev/null 2>&1; then
    warn_check "sshd command is unavailable"
    return
  fi

  local effective
  effective="$(sshd -T 2>/dev/null || true)"
  if grep -qix 'permitrootlogin no' <<<"$effective"; then
    pass "Effective SSH policy denies root login"
  else
    warn_check "Effective SSH policy does not report PermitRootLogin no"
  fi

  if grep -qix 'passwordauthentication no' <<<"$effective"; then
    pass "Effective SSH policy disables password authentication"
  else
    warn_check "Effective SSH policy does not report PasswordAuthentication no"
  fi
}

check_sudo() {
  if visudo -c >/dev/null 2>&1; then
    pass "sudoers configuration parses successfully"
  else
    fail_check "sudoers configuration validation failed"
  fi
}

check_network_exposure() {
  local listeners
  listeners="$(ss -lntupH 2>/dev/null || true)"
  if [[ -z "$listeners" ]]; then
    pass "No listening TCP/UDP sockets reported"
    return
  fi

  info_check "Listening TCP/UDP sockets are present; review inventory below"
  printf '%s\n' "$listeners" | sed 's/^/       /'
}

check_firewall() {
  if systemctl is-active --quiet firewalld.service 2>/dev/null; then
    pass "firewalld.service is active"
  elif systemctl is-active --quiet nftables.service 2>/dev/null; then
    pass "nftables.service is active"
  elif systemctl is-active --quiet ufw.service 2>/dev/null; then
    pass "ufw.service is active"
  else
    warn_check "No active firewalld, nftables or ufw service detected"
  fi
}

check_tpm_policy() {
  if grep -Eq '^[[:space:]]*tpm2:[[:space:]]*true' "${REPO_ROOT}/profiles/dell-latitude-e5470/profile.yaml"; then
    info_check "TPM2 unlock is declared enabled in profile"
  else
    info_check "TPM2 unlock is not enabled in profile"
  fi
}

check_repository_secret_filenames() {
  local matches
  matches="$(git -C "$REPO_ROOT" ls-files | grep -Ei '(^|/)(\.env($|\.)|id_(rsa|dsa|ecdsa|ed25519)$|.*\.(pem|p12|pfx|key)$)' || true)"
  if [[ -z "$matches" ]]; then
    pass "No obvious secret-bearing filenames are tracked by Git"
  else
    warn_check "Potential secret-bearing filenames are tracked; review without printing their contents"
    printf '%s\n' "$matches" | sed 's/^/       /'
  fi
}

show_summary() {
  printf '\n========================================\n'
  printf 'Security baseline summary\n'
  printf '========================================\n\n'
  printf 'Passed:   %d\n' "$passed"
  printf 'Info:     %d\n' "$info_count"
  printf 'Warnings: %d\n' "$warnings"
  printf 'Failed:   %d\n' "$failed"
}

main() {
  require_root
  require_commands cryptsetup findmnt git grep lsblk sed ss systemctl visudo
  require_arch_systemd

  printf '\nSecurity baseline\n-----------------\n\n'
  check_root_encryption
  check_secure_boot
  check_sshd
  check_sudo
  check_network_exposure
  check_firewall
  check_tpm_policy
  check_repository_secret_filenames
  show_summary

  ((failed == 0)) || exit 1
}

main "$@"
