#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/system/services.txt"
readonly REQUIRED_SERVICES=(NetworkManager.service bluetooth.service)

declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  printf 'Usage:\n  sudo ./%s\n\nPackage source:\n  %s\n' "$SCRIPT_NAME" "$PACKAGE_FILE"
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

confirm_configuration() {
  local confirmation
  printf '\nType SERVICES to configure the base services: '
  read -r confirmation
  [[ "$confirmation" == "SERVICES" ]] || die "System service configuration was not authorized."
}

main() {
  require_root
  require_commands awk pacman systemctl
  require_arch_systemd
  parse_arguments "$@"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages

  printf '\nSystem services\n---------------\n\nPackage source:\n  %s\n\nPackages:\n' "$PACKAGE_FILE"
  printf '  - %s\n' "${PACKAGES[@]}"
  printf '\nServices:\n  - NetworkManager.service\n  - bluetooth.service\n'
  confirm_configuration

  install_missing_packages
  validate_installed_packages

  local service
  for service in "${REQUIRED_SERVICES[@]}"; do
    systemctl cat "$service" >/dev/null 2>&1 || die "Required service is unavailable: $service"
    systemctl enable "$service"
  done

  systemctl start NetworkManager.service
  systemctl is-enabled --quiet NetworkManager.service || die "NetworkManager.service is not enabled."
  systemctl is-active --quiet NetworkManager.service || die "NetworkManager.service is not active."

  if [[ -d /sys/class/bluetooth ]]; then
    systemctl start bluetooth.service
    systemctl is-active --quiet bluetooth.service || log_warn "bluetooth.service is enabled but not active."
  else
    log_warn "No Bluetooth controller is currently exposed by the kernel; bluetooth.service remains enabled for future boots."
  fi

  systemctl is-enabled --quiet bluetooth.service || die "bluetooth.service is not enabled."

  printf '\nBase system services configured successfully.\n\nNext step:\n  10-configure-ssh\n'
}

main "$@"
