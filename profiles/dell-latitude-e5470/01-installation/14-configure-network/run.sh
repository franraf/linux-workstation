#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_HOSTNAME="linux-workstation"
readonly NETWORK_MANAGER_SERVICE="NetworkManager.service"

SYSTEM_HOSTNAME="$DEFAULT_HOSTNAME"

log() {
  printf '[INFO] %s\n' "$*"
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
  ./$SCRIPT_NAME [options]

Options:
  --hostname <name>
      Static hostname assigned to the workstation.
      Default: ${DEFAULT_HOSTNAME}

  --help, -h
      Show this help message.

Examples:
  ./$SCRIPT_NAME

  ./$SCRIPT_NAME --hostname linux-workstation

This script must run inside the installed Arch Linux system.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    cat
    grep
    install
    pacman
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
      --hostname)
        (($# >= 2)) ||
          die "Missing value for --hostname."

        SYSTEM_HOSTNAME="$2"
        shift 2
        ;;

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
    die "This script must run inside the installed Arch Linux system."

  [[ -s /etc/fstab ]] ||
    die "The installed-system fstab is missing or empty."
}

validate_hostname() {
  local hostname_length="${#SYSTEM_HOSTNAME}"

  ((hostname_length >= 1 && hostname_length <= 63)) ||
    die "Hostname must contain between 1 and 63 characters."

  [[ "$SYSTEM_HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] ||
    die "Hostname must use lowercase letters, digits and internal hyphens only."

  [[ "$SYSTEM_HOSTNAME" != *"--"* ]] ||
    die "Hostname must not contain consecutive hyphens."
}

validate_network_manager_package() {
  pacman -Q networkmanager >/dev/null 2>&1 ||
    die "The networkmanager package is not installed."

  [[ -x /usr/bin/nmcli ]] ||
    die "nmcli is unavailable."

  [[ -x /usr/bin/nmtui ]] ||
    die "nmtui is unavailable."

  [[ -f "/usr/lib/systemd/system/${NETWORK_MANAGER_SERVICE}" ]] ||
    die "${NETWORK_MANAGER_SERVICE} is unavailable."
}

show_plan() {
  cat <<EOF

Network configuration
---------------------

Hostname:        $SYSTEM_HOSTNAME
Hostname file:   /etc/hostname
Hosts file:      /etc/hosts
Network service: $NETWORK_MANAGER_SERVICE

The service will be enabled for the first boot.
No Wi-Fi password or connection profile will be stored by this script.
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType NETWORK to apply the network configuration: '
  read -r confirmation

  [[ "$confirmation" == "NETWORK" ]] ||
    die "Network configuration was not authorized."
}

configure_hostname() {
  log "Writing /etc/hostname."

  printf '%s\n' "$SYSTEM_HOSTNAME" |
    install \
      --mode 0644 \
      /dev/stdin \
      /etc/hostname
}

configure_hosts() {
  log "Writing /etc/hosts."

  cat <<EOF |
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${SYSTEM_HOSTNAME}.localdomain ${SYSTEM_HOSTNAME}
EOF
    install \
      --mode 0644 \
      /dev/stdin \
      /etc/hosts
}

enable_network_manager() {
  log "Enabling ${NETWORK_MANAGER_SERVICE}."

  systemctl enable "$NETWORK_MANAGER_SERVICE"
}

validate_hostname_file() {
  [[ -f /etc/hostname ]] ||
    die "/etc/hostname was not created."

  [[ "$(cat /etc/hostname)" == "$SYSTEM_HOSTNAME" ]] ||
    die "/etc/hostname does not contain the expected hostname."
}

validate_hosts_file() {
  [[ -f /etc/hosts ]] ||
    die "/etc/hosts was not created."

  grep -Eq \
    '^[[:space:]]*127\.0\.0\.1[[:space:]]+localhost[[:space:]]*$' \
    /etc/hosts ||
    die "IPv4 localhost entry is missing from /etc/hosts."

  grep -Eq \
    '^[[:space:]]*::1[[:space:]]+localhost[[:space:]]*$' \
    /etc/hosts ||
    die "IPv6 localhost entry is missing from /etc/hosts."

  grep -Eq \
    "^[[:space:]]*127\\.0\\.1\\.1[[:space:]]+${SYSTEM_HOSTNAME}\\.localdomain[[:space:]]+${SYSTEM_HOSTNAME}[[:space:]]*$" \
    /etc/hosts ||
    die "Static hostname entry is missing from /etc/hosts."
}

validate_service_enabled() {
  systemctl is-enabled --quiet "$NETWORK_MANAGER_SERVICE" ||
    die "${NETWORK_MANAGER_SERVICE} was not enabled."

  local wants_link

  wants_link="/etc/systemd/system/multi-user.target.wants/${NETWORK_MANAGER_SERVICE}"

  [[ -L "$wants_link" ]] ||
    die "NetworkManager enablement link was not created."
}

validate_no_connection_secrets() {
  local connection_directory="/etc/NetworkManager/system-connections"

  if [[ ! -d "$connection_directory" ]]; then
    return
  fi

  if find "$connection_directory" \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
    -print \
    -quit |
    grep -q .; then
    die "Unexpected NetworkManager connection profiles were found."
  fi
}

show_result() {
  printf '\nNetwork configuration completed successfully.\n\n'

  printf '/etc/hostname:\n'
  sed 's/^/  /' /etc/hostname

  printf '\n/etc/hosts:\n'
  sed 's/^/  /' /etc/hosts

  printf '\nNetwork service:\n'
  printf '  %s: %s\n' \
    "$NETWORK_MANAGER_SERVICE" \
    "$(systemctl is-enabled "$NETWORK_MANAGER_SERVICE")"

  printf '\nFirst-boot connection:\n'
  printf '  Wired: managed automatically when available\n'
  printf '  Wi-Fi: configure interactively with nmcli or nmtui\n'

  printf '\nNext step:\n'
  printf '  15-configure-users\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_hostname
  validate_network_manager_package
  show_plan
  confirm_configuration
  configure_hostname
  configure_hosts
  enable_network_manager
  validate_hostname_file
  validate_hosts_file
  validate_service_enabled
  validate_no_connection_secrets
  show_result
}

main "$@"
