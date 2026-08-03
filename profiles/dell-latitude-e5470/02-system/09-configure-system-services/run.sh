```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly NETWORK_MANAGER_PACKAGE="networkmanager"
readonly NETWORK_MANAGER_SERVICE="NetworkManager.service"

readonly BLUEZ_PACKAGE="bluez"
readonly BLUEZ_UTILS_PACKAGE="bluez-utils"
readonly BLUETOOTH_SERVICE="bluetooth.service"

readonly REQUIRED_PACKAGES=(
  "$NETWORK_MANAGER_PACKAGE"
  "$BLUEZ_PACKAGE"
  "$BLUEZ_UTILS_PACKAGE"
)

readonly REQUIRED_SERVICES=(
  "$NETWORK_MANAGER_SERVICE"
  "$BLUETOOTH_SERVICE"
)

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

This script configures the base system services required by the
linux-workstation profile.

Managed services:

  ${NETWORK_MANAGER_SERVICE}
  ${BLUETOOTH_SERVICE}

Managed packages:

  ${NETWORK_MANAGER_PACKAGE}
  ${BLUEZ_PACKAGE}
  ${BLUEZ_UTILS_PACKAGE}

Services managed by dedicated playbooks are intentionally excluded.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    pacman
    systemctl
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

System services
---------------

Network
  Package: ${NETWORK_MANAGER_PACKAGE}
  Service: ${NETWORK_MANAGER_SERVICE}

Bluetooth
  Packages:
    ${BLUEZ_PACKAGE}
    ${BLUEZ_UTILS_PACKAGE}

  Service:
    ${BLUETOOTH_SERVICE}

Excluded from this step
-----------------------

systemd-timesyncd
fstrim.timer
sshd.service

These are managed by their dedicated playbooks.
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType SERVICES to configure the base services: '
  read -r confirmation

  [[ "$confirmation" == "SERVICES" ]] ||
    die "System service configuration was not authorized."
}

install_required_packages() {
  local missing_packages=()
  local package

  for package in "${REQUIRED_PACKAGES[@]}"; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      log "$package is already installed."
    else
      missing_packages+=("$package")
    fi
  done

  if ((${#missing_packages[@]} == 0)); then
    return
  fi

  log "Installing missing system-service packages."

  pacman \
    --sync \
    --needed \
    "${missing_packages[@]}"
}

validate_packages() {
  local package

  for package in "${REQUIRED_PACKAGES[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 ||
      die "Required package is not installed: $package"
  done
}

validate_services_available() {
  local service

  for service in "${REQUIRED_SERVICES[@]}"; do
    systemctl cat "$service" >/dev/null 2>&1 ||
      die "Required service is unavailable: $service"
  done
}

enable_services() {
  local service

  for service in "${REQUIRED_SERVICES[@]}"; do
    log "Enabling $service."

    systemctl enable "$service"
  done
}

start_network_manager() {
  log "Starting ${NETWORK_MANAGER_SERVICE}."

  systemctl start "$NETWORK_MANAGER_SERVICE"
}

start_bluetooth_if_available() {
  if [[ ! -d /sys/class/bluetooth ]]; then
    warn "No Bluetooth controller is currently exposed by the kernel."
    warn "${BLUETOOTH_SERVICE} will remain enabled for future boots."
    return
  fi

  log "Starting ${BLUETOOTH_SERVICE}."

  systemctl start "$BLUETOOTH_SERVICE"
}

validate_service_enabled() {
  local service=$1

  systemctl is-enabled --quiet "$service" ||
    die "Service is not enabled: $service"
}

validate_network_manager() {
  validate_service_enabled "$NETWORK_MANAGER_SERVICE"

  systemctl is-active --quiet "$NETWORK_MANAGER_SERVICE" ||
    die "${NETWORK_MANAGER_SERVICE} is not active."
}

validate_bluetooth() {
  validate_service_enabled "$BLUETOOTH_SERVICE"

  if [[ ! -d /sys/class/bluetooth ]]; then
    warn "Bluetooth hardware is not currently visible."
    return
  fi

  if ! systemctl is-active --quiet "$BLUETOOTH_SERVICE"; then
    warn "${BLUETOOTH_SERVICE} is enabled but not active."
    warn "Review the Bluetooth hardware state before continuing."
  fi
}

validate_network_manager_wait_online() {
  local state

  state="$(
    systemctl is-enabled NetworkManager-wait-online.service \
      2>/dev/null || true
  )"

  case "$state" in
    enabled)
      log "NetworkManager-wait-online.service is enabled."
      ;;

    disabled)
      warn "NetworkManager-wait-online.service is disabled."
      warn "This is acceptable unless a future service requires network-online.target."
      ;;

    *)
      warn "Unable to determine NetworkManager-wait-online.service state."
      ;;
  esac
}

show_result() {
  printf '\nBase system services configured successfully.\n\n'

  printf 'Packages:\n'
  printf '  %s\n' "${REQUIRED_PACKAGES[@]}"

  printf '\nServices:\n'

  local service

  for service in "${REQUIRED_SERVICES[@]}"; do
    printf '  %-30s enabled=%s active=%s\n' \
      "$service" \
      "$(systemctl is-enabled "$service" 2>/dev/null || true)" \
      "$(systemctl is-active "$service" 2>/dev/null || true)"
  done

  printf '\nNext step:\n'
  printf '  10-configure-ssh\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  show_plan
  confirm_configuration
  install_required_packages
  validate_packages
  validate_services_available
  enable_services
  start_network_manager
  start_bluetooth_if_available
  validate_network_manager
  validate_bluetooth
  validate_network_manager_wait_online
  show_result
}

main "$@"
```

