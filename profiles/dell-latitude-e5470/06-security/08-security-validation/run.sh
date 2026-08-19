#!/usr/bin/env bash
set -Eeuo pipefail

passed=0
warnings=0
failed=0

pass() {
  printf '[PASS] %s\n' "$*"
  ((passed += 1))
}
warn() {
  printf '[WARN] %s\n' "$*"
  ((warnings += 1))
}
fail() {
  printf '[FAIL] %s\n' "$*"
  ((failed += 1))
}

[[ $EUID -eq 0 ]] || {
  echo '[ERROR] Run with sudo.' >&2
  exit 1
}

printf '\nSecurity validation\n-------------------\n\n'

if cryptsetup status cryptroot 2>/dev/null | grep -q 'type:[[:space:]]*LUKS2'; then
  pass 'cryptroot is active as LUKS2'
else
  fail 'cryptroot is not confirmed as active LUKS2'
fi

boot_status="$(bootctl status 2>/dev/null || true)"
if grep -qi 'Secure Boot: enabled' <<<"$boot_status"; then
  pass 'Secure Boot is enabled'
else
  fail 'Secure Boot is not enabled'
fi

if grep -qi 'Measured UKI: yes' <<<"$boot_status" && grep -qi 'Measured OS: yes' <<<"$boot_status"; then
  pass 'UKI and OS are measured'
else
  fail 'Current boot is not reported as measured UKI/OS'
fi

if grep -q 'Current Entry: arch-linux-uki.efi' <<<"$boot_status" && grep -q 'Product: systemd-stub' <<<"$boot_status"; then
  pass 'Current boot uses arch-linux-uki.efi through systemd-stub'
else
  fail 'Current boot is not the validated UKI/systemd-stub path'
fi

if command -v sbctl >/dev/null 2>&1 && sbctl verify >/dev/null 2>&1; then
  pass 'sbctl verifies registered EFI artifacts'
else
  fail 'sbctl verification failed'
fi

enroll="$(systemd-cryptenroll /dev/sda2 2>/dev/null || true)"
password_slots="$(awk '$2 == "password" {n++} END {print n+0}' <<<"$enroll")"
tpm_slots="$(awk '$2 == "tpm2" {n++} END {print n+0}' <<<"$enroll")"
if ((password_slots >= 2)); then
  pass 'At least two LUKS password slots are preserved'
else
  fail 'Expected at least two independent LUKS password slots'
fi
if ((tpm_slots >= 1)); then
  pass 'TPM2 LUKS token is enrolled'
else
  fail 'TPM2 LUKS token is not enrolled'
fi

sshd_effective="$(sshd -T 2>/dev/null || true)"
if grep -qi '^permitrootlogin no$' <<<"$sshd_effective"; then
  pass 'SSH root login is disabled'
else
  fail 'SSH root login is not disabled'
fi
if grep -qi '^passwordauthentication no$' <<<"$sshd_effective"; then
  pass 'SSH password authentication is disabled'
else
  fail 'SSH password authentication is still enabled'
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)"
secret_names="$(git -C "$repo_root" ls-files | grep -Ei '(^|/)(\.env($|\.)|id_(rsa|dsa|ecdsa|ed25519)$|.*\.(pem|p12|pfx|key)$)' || true)"
if [[ -z $secret_names ]]; then
  pass 'No obvious secret-bearing filenames are tracked by Git'
else
  fail 'Potential secret-bearing filenames are tracked by Git'
fi

warn 'Hardware token is optional and currently deferred'

printf '\n========================================\n'
printf 'Security validation summary\n'
printf '========================================\n\n'
printf 'Passed:   %d\n' "$passed"
printf 'Warnings: %d\n' "$warnings"
printf 'Failed:   %d\n' "$failed"

((failed == 0))
