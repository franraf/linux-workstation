```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly SSH_PACKAGE="openssh"
readonly SSH_SERVICE="sshd.service"

readonly CONFIG_DIRECTORY="/etc/ssh/sshd_config.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"

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

This script installs and configures the OpenSSH server.

Package:
  ${SSH_PACKAGE}

Service:
  ${SSH_SERVICE}

Configuration:
  ${CONFIG_FILE}

Managed policy:

  PermitRootLogin no
  PubkeyAuthentication yes
  PasswordAuthentication yes
  PermitEmptyPasswords no
  KbdInteractiveAuthentication no
  X11Forwarding no

Password authentication remains enabled during the base-system phase.
Further hardening belongs to the security phase.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    install
    mktemp
    pacman
    sshd
    systemctl
    find
    sed
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

  [[ -d /run/systemd/system ]] ||
    die "systemd is not running as PID 1."
}

show_plan() {
  cat <<EOF

OpenSSH configuration
---------------------

Package:
  ${SSH_PACKAGE}

Service:
  ${SSH_SERVICE}

Configuration:
  ${CONFIG_FILE}

Authentication
--------------

Root login:
  disabled

Public key authentication:
  enabled

Password authentication:
  enabled

Empty passwords:
  disabled

Keyboard-interactive authentication:
  disabled

X11 forwarding:
  disabled

Password authentication is intentionally retained during this phase
to avoid requiring SSH key provisioning before remote access works.
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType SSH to configure OpenSSH: '
  read -r confirmation

  [[ "$confirmation" == "SSH" ]] ||
    die "OpenSSH configuration was not authorized."
}

install_package() {
  if pacman -Q "$SSH_PACKAGE" >/dev/null 2>&1; then
    log "${SSH_PACKAGE} is already installed."
    return
  fi

  log "Installing ${SSH_PACKAGE}."

  pacman \
    --sync \
    --needed \
    "$SSH_PACKAGE"
}

validate_package() {
  pacman -Q "$SSH_PACKAGE" >/dev/null 2>&1 ||
    die "${SSH_PACKAGE} is not installed."

  command -v sshd >/dev/null 2>&1 ||
    die "sshd executable is unavailable."

  systemctl cat "$SSH_SERVICE" >/dev/null 2>&1 ||
    die "${SSH_SERVICE} is unavailable."
}

write_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
# Managed by linux-workstation.
# Profile: dell-latitude-e5470

PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
KbdInteractiveAuthentication no
X11Forwarding no
EOF

  install \
    --directory \
    --owner root \
    --group root \
    --mode 0755 \
    "$CONFIG_DIRECTORY"

  install \
    --owner root \
    --group root \
    --mode 0644 \
    "$temporary_file" \
    "$CONFIG_FILE"

  rm -f "$temporary_file"
  trap - RETURN
}

validate_configuration_file() {
  [[ -s "$CONFIG_FILE" ]] ||
    die "OpenSSH configuration file was not created."

  grep -Fxq 'PermitRootLogin no' "$CONFIG_FILE" ||
    die "PermitRootLogin policy is incorrect."

  grep -Fxq 'PubkeyAuthentication yes' "$CONFIG_FILE" ||
    die "PubkeyAuthentication policy is incorrect."

  grep -Fxq 'PasswordAuthentication yes' "$CONFIG_FILE" ||
    die "PasswordAuthentication policy is incorrect."

  grep -Fxq 'PermitEmptyPasswords no' "$CONFIG_FILE" ||
    die "PermitEmptyPasswords policy is incorrect."

  grep -Fxq 'KbdInteractiveAuthentication no' "$CONFIG_FILE" ||
    die "KbdInteractiveAuthentication policy is incorrect."

  grep -Fxq 'X11Forwarding no' "$CONFIG_FILE" ||
    die "X11Forwarding policy is incorrect."
}

validate_sshd_syntax() {
  log "Validating sshd configuration syntax."

  sshd -t ||
    die "OpenSSH configuration validation failed."
}

validate_effective_configuration() {
  local effective_config

  effective_config="$(sshd -T)"

  grep -Fxq 'permitrootlogin no' <<<"$effective_config" ||
    die "PermitRootLogin=no is not effective."

  grep -Fxq 'pubkeyauthentication yes' <<<"$effective_config" ||
    die "PubkeyAuthentication=yes is not effective."

  grep -Fxq 'passwordauthentication yes' <<<"$effective_config" ||
    die "PasswordAuthentication=yes is not effective."

  grep -Fxq 'permitemptypasswords no' <<<"$effective_config" ||
    die "PermitEmptyPasswords=no is not effective."

  grep -Fxq 'kbdinteractiveauthentication no' <<<"$effective_config" ||
    die "KbdInteractiveAuthentication=no is not effective."

  grep -Fxq 'x11forwarding no' <<<"$effective_config" ||
    die "X11Forwarding=no is not effective."
}

enable_service() {
  log "Enabling ${SSH_SERVICE}."

  systemctl enable "$SSH_SERVICE"
}

restart_service() {
  log "Restarting ${SSH_SERVICE}."

  systemctl restart "$SSH_SERVICE"
}

validate_service() {
  systemctl is-enabled --quiet "$SSH_SERVICE" ||
    die "${SSH_SERVICE} is not enabled."

  systemctl is-active --quiet "$SSH_SERVICE" ||
    die "${SSH_SERVICE} is not active."
}

validate_host_keys() {
  local host_keys

  host_keys="$(
    find /etc/ssh \
      -maxdepth 1 \
      -type f \
      -name 'ssh_host_*_key' \
      -print
  )"

  [[ -n "$host_keys" ]] ||
    die "No OpenSSH host private keys were found."
}

show_result() {
  printf '\nOpenSSH configured successfully.\n\n'

  printf 'Configuration:\n'
  printf '  %s\n' "$CONFIG_FILE"

  printf '\nService:\n'
  printf '  enabled: %s\n' \
    "$(systemctl is-enabled "$SSH_SERVICE")"

  printf '  active:  %s\n' \
    "$(systemctl is-active "$SSH_SERVICE")"

  printf '\nEffective policy:\n'

  sshd -T |
    grep -E \
      '^(permitrootlogin|pubkeyauthentication|passwordauthentication|permitemptypasswords|kbdinteractiveauthentication|x11forwarding) ' |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  11-install-base-packages\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  show_plan
  confirm_configuration
  install_package
  validate_package
  write_configuration
  validate_configuration_file
  validate_sshd_syntax
  validate_effective_configuration
  enable_service
  restart_service
  validate_service
  validate_host_keys
  show_result
}

main "$@"
```
