#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly DEFAULT_HOSTNAME="linux-workstation"
readonly NETWORK_MANAGER_SERVICE="NetworkManager.service"
readonly HOSTS_TEMPLATE="${REPO_ROOT}/system/network/hosts.template"

SYSTEM_HOSTNAME="$DEFAULT_HOSTNAME"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [--hostname <name>]

Default hostname:
  ${DEFAULT_HOSTNAME}

Hosts template:
  ${HOSTS_TEMPLATE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --hostname) (($# >= 2)) || die "Missing value for --hostname."; SYSTEM_HOSTNAME="$2"; shift 2 ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

validate_execution_context() {
  require_arch_linux
  [[ -s /etc/fstab ]] || die "The installed-system fstab is missing or empty."
}

validate_hostname() {
  local length="${#SYSTEM_HOSTNAME}"
  ((length >= 1 && length <= 63)) || die "Hostname must contain between 1 and 63 characters."
  [[ "$SYSTEM_HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] ||
    die "Hostname must use lowercase letters, digits and internal hyphens only."
  [[ "$SYSTEM_HOSTNAME" != *"--"* ]] || die "Hostname must not contain consecutive hyphens."
}

validate_network_manager() {
  require_package_installed networkmanager "Install the base system package set first."
  require_commands nmcli nmtui systemctl
  [[ -f "/usr/lib/systemd/system/${NETWORK_MANAGER_SERVICE}" ]] || die "${NETWORK_MANAGER_SERVICE} is unavailable."
}

show_plan() {
  printf '\nNetwork configuration\n'
  printf '%s\n\n' '---------------------'
  printf 'Hostname:\n  %s\n\n' "$SYSTEM_HOSTNAME"
  printf 'Hosts template:\n  %s\n\n' "$HOSTS_TEMPLATE"
  printf 'Service:\n  %s\n' "$NETWORK_MANAGER_SERVICE"
}

confirm_configuration() {
  local confirmation
  printf '\nType NETWORK to apply the network configuration: '
  read -r confirmation
  [[ "$confirmation" == "NETWORK" ]] || die "Network configuration was not authorized."
}

configure_hostname() {
  printf '%s\n' "$SYSTEM_HOSTNAME" | install --mode 0644 /dev/stdin /etc/hostname
}

configure_hosts() {
  local temporary_file
  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN
  sed "s/@HOSTNAME@/${SYSTEM_HOSTNAME}/g" "$HOSTS_TEMPLATE" >"$temporary_file"
  install --mode 0644 "$temporary_file" /etc/hosts
  rm -f "$temporary_file"
  trap - RETURN
}

enable_network_manager() {
  systemctl enable "$NETWORK_MANAGER_SERVICE"
}

validate_configuration() {
  [[ "$(cat /etc/hostname)" == "$SYSTEM_HOSTNAME" ]] || die "/etc/hostname does not contain the expected hostname."
  grep -Eq '^[[:space:]]*127\.0\.0\.1[[:space:]]+localhost[[:space:]]*$' /etc/hosts || die "IPv4 localhost entry is missing."
  grep -Eq '^[[:space:]]*::1[[:space:]]+localhost[[:space:]]*$' /etc/hosts || die "IPv6 localhost entry is missing."
  grep -Eq "^[[:space:]]*127\\.0\\.1\\.1[[:space:]]+${SYSTEM_HOSTNAME}\\.localdomain[[:space:]]+${SYSTEM_HOSTNAME}[[:space:]]*$" /etc/hosts ||
    die "Static hostname entry is missing."
  systemctl is-enabled --quiet "$NETWORK_MANAGER_SERVICE" || die "${NETWORK_MANAGER_SERVICE} was not enabled."
}

validate_no_connection_secrets() {
  local directory="/etc/NetworkManager/system-connections"
  [[ ! -d "$directory" ]] && return 0
  [[ -z "$(find "$directory" -mindepth 1 -maxdepth 1 -type f -print -quit)" ]] ||
    die "Unexpected NetworkManager connection profiles were found."
}

show_result() {
  printf '\nNetwork configuration completed successfully.\n\n'
  printf 'Hostname:\n  %s\n' "$SYSTEM_HOSTNAME"
  printf '\nNetwork service:\n  %s: %s\n' "$NETWORK_MANAGER_SERVICE" "$(systemctl is-enabled "$NETWORK_MANAGER_SERVICE")"
  printf '\nNext step:\n  15-configure-users\n'
}

main() {
  require_root
  require_commands cat find grep install mktemp sed systemctl
  parse_arguments "$@"
  validate_execution_context
  validate_hostname
  validate_network_manager
  [[ -s "$HOSTS_TEMPLATE" ]] || die "Canonical hosts template is missing."
  show_plan
  confirm_configuration
  configure_hostname
  configure_hosts
  enable_network_manager
  validate_configuration
  validate_no_connection_secrets
  show_result
}

main "$@"
