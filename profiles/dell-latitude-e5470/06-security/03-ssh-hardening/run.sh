#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly SOURCE_CONFIG="${REPO_ROOT}/system/openssh/10-linux-workstation.conf"
readonly TARGET_CONFIG="/etc/ssh/sshd_config.d/10-linux-workstation.conf"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

main() {
  local target_user target_home authorized_keys effective confirmation

  require_root
  require_commands cmp getent install sshd systemctl
  require_arch_systemd

  [[ -r "$SOURCE_CONFIG" ]] || die "Canonical SSH config is missing: $SOURCE_CONFIG"

  target_user="${SUDO_USER:-}"
  [[ -n "$target_user" && "$target_user" != root ]] || die "Run this step with sudo from the target non-root user session."

  target_home="$(getent passwd "$target_user" | cut -d: -f6)"
  [[ -n "$target_home" ]] || die "Could not resolve home directory for $target_user."

  authorized_keys="${target_home}/.ssh/authorized_keys"
  if [[ ! -s "$authorized_keys" ]]; then
    die "No non-empty authorized_keys found for ${target_user}: ${authorized_keys}. Refusing to disable SSH password authentication."
  fi

  printf '\nSSH hardening\n-------------\n\n'
  printf 'Target user: %s\n' "$target_user"
  printf 'Canonical config: %s\n' "$SOURCE_CONFIG"
  printf 'Installed config: %s\n\n' "$TARGET_CONFIG"
  printf 'This step will disable SSH password authentication and preserve public-key authentication.\n'
  printf 'Keep any current remote session open until a new key-authenticated session is tested.\n\n'
  printf 'Type SSH to apply the canonical SSH policy: '
  read -r confirmation
  [[ "$confirmation" == "SSH" ]] || die "SSH hardening was not authorized."

  install -D -m 0644 "$SOURCE_CONFIG" "$TARGET_CONFIG"

  if ! sshd -t; then
    die "sshd configuration validation failed after installing canonical policy."
  fi

  effective="$(sshd -T)"

  grep -qi '^permitrootlogin no$' <<<"$effective" || die "Effective SSH policy does not deny root login."
  grep -qi '^pubkeyauthentication yes$' <<<"$effective" || die "Effective SSH policy does not enable public-key authentication."
  grep -qi '^passwordauthentication no$' <<<"$effective" || die "Effective SSH policy does not disable password authentication."
  grep -qi '^kbdinteractiveauthentication no$' <<<"$effective" || die "Effective SSH policy does not disable keyboard-interactive authentication."

  systemctl reload sshd.service

  printf '\nSSH policy applied and sshd reloaded successfully.\n\n'
  printf 'Manual validation still required:\n'
  printf '  - from another terminal/host, open a NEW SSH session as %s using public-key authentication\n' "$target_user"
  printf '  - do not close an existing remote session until the new session succeeds\n'
  printf '  - verify password authentication is rejected\n'
}

main "$@"
