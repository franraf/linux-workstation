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
info_count=0
warnings=0
failed=0

pass() {
  printf '[PASS] %s\n' "$*"
  ((passed += 1))
}
info_check() {
  printf '[INFO] %s\n' "$*"
  ((info_count += 1))
}
warn_check() {
  printf '[WARN] %s\n' "$*"
  ((warnings += 1))
}
fail_check() {
  printf '[FAIL] %s\n' "$*"
  ((failed += 1))
}

main() {
  local backing_device dump json boot_entries active_slots token_count

  require_root
  require_commands cryptsetup findmnt grep jq lsblk
  require_arch_systemd

  printf '\nDisk encryption review\n----------------------\n\n'

  if cryptsetup status cryptroot >/dev/null 2>&1; then
    pass "cryptroot mapper is active"
  else
    fail_check "cryptroot mapper is not active"
    backing_device=""
  fi

  backing_device="$(cryptsetup status cryptroot 2>/dev/null | awk -F': ' '/device:/ {gsub(/^[[:space:]]+/, "", $2); print $2; exit}')"
  if [[ -n "$backing_device" && -b "$backing_device" ]]; then
    pass "Encrypted backing device identified: ${backing_device}"
  else
    fail_check "Unable to identify encrypted backing device"
  fi

  if [[ -n "$backing_device" ]]; then
    dump="$(cryptsetup luksDump "$backing_device" 2>/dev/null || true)"
    json="$(cryptsetup luksDump --dump-json-metadata "$backing_device" 2>/dev/null || true)"

    grep -q '^Version:[[:space:]]*2$' <<<"$dump" && pass "Container format is LUKS2" || fail_check "Container is not confirmed as LUKS2"
    grep -q 'cipher: aes-xts-plain64' <<<"$dump" && pass "Data cipher is aes-xts-plain64" || fail_check "Unexpected data cipher"
    grep -q 'Key:[[:space:]]*512 bits' <<<"$dump" && pass "Active keyslot uses a 512-bit XTS key" || fail_check "Expected 512-bit XTS key was not found"

    if jq -e '.keyslots | to_entries | any(.value.kdf.type == "argon2id")' <<<"$json" >/dev/null 2>&1; then
      pass "At least one active keyslot uses Argon2id"
    else
      fail_check "No Argon2id keyslot found"
    fi

    active_slots="$(jq '.keyslots | length' <<<"$json" 2>/dev/null || printf '0')"
    token_count="$(jq '.tokens | length' <<<"$json" 2>/dev/null || printf '0')"

    if ((active_slots == 1)); then
      warn_check "Exactly one LUKS keyslot is active; recovery credential is not yet provisioned"
    else
      info_check "Active LUKS keyslots: ${active_slots}"
    fi

    info_check "Registered LUKS2 tokens: ${token_count}"
  fi

  if grep -Eq '^HOOKS=.*systemd' /etc/mkinitcpio.conf; then
    pass "mkinitcpio uses the systemd hook"
  else
    fail_check "mkinitcpio systemd hook not found"
  fi

  boot_entries="$(grep -RhsE '^options .*rd\.luks\.name=.*=cryptroot' /boot/loader/entries 2>/dev/null || true)"
  if [[ -n "$boot_entries" ]]; then
    pass "systemd-boot entries declare rd.luks.name for cryptroot"
  else
    fail_check "No systemd-boot rd.luks.name entry for cryptroot found"
  fi

  if grep -RhsE '^options .*rd\.luks\.options=.*=discard' /boot/loader/entries 2>/dev/null | grep -q .; then
    warn_check "Encrypted root enables discard; accepted SSD trade-off for this generation"
  else
    info_check "Encrypted root discard option was not detected"
  fi

  printf '\n========================================\n'
  printf 'Disk encryption review summary\n'
  printf '========================================\n\n'
  printf 'Passed:   %d\n' "$passed"
  printf 'Info:     %d\n' "$info_count"
  printf 'Warnings: %d\n' "$warnings"
  printf 'Failed:   %d\n' "$failed"

  ((failed == 0)) || exit 1
}

main "$@"
