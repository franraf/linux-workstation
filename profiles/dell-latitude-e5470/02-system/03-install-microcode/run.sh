#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly MICROCODE_PACKAGE="intel-ucode"
readonly MICROCODE_IMAGE="/boot/intel-ucode.img"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() { printf 'Usage:\n  sudo ./%s\n' "$SCRIPT_NAME"; }

validate_cpu_vendor() {
  local vendor
  vendor="$(awk -F: '$1 ~ /^[[:space:]]*vendor_id[[:space:]]*$/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}' /proc/cpuinfo)"
  [[ "$vendor" == "GenuineIntel" ]] || die "Expected an Intel CPU, found vendor: ${vendor:-unknown}"
}

show_plan() {
  printf '\nMicrocode configuration\n-----------------------\n\nPackage: %s\nImage:   %s\n' "$MICROCODE_PACKAGE" "$MICROCODE_IMAGE"
}

confirm_installation() {
  local confirmation
  printf '\nType MICROCODE to continue: '
  read -r confirmation
  [[ "$confirmation" == "MICROCODE" ]] || die "Microcode installation was not authorized."
}

install_microcode() {
  if pacman -Q "$MICROCODE_PACKAGE" >/dev/null 2>&1; then
    log_info "${MICROCODE_PACKAGE} is already installed."
    return 0
  fi
  pacman -S --needed "$MICROCODE_PACKAGE"
}

validate_microcode() {
  pacman -Q "$MICROCODE_PACKAGE" >/dev/null 2>&1 || die "${MICROCODE_PACKAGE} is not installed."
  [[ -s "$MICROCODE_IMAGE" ]] || die "Microcode image is missing or empty: $MICROCODE_IMAGE"
  grep -Rqs "initrd[[:space:]]\+${MICROCODE_IMAGE#/boot}" /boot/loader/entries || die "No systemd-boot entry references ${MICROCODE_IMAGE#/boot}."
}

show_result() {
  printf '\nIntel microcode support validated successfully.\n\nPackage:\n  %s\n\nNext step:\n  04-configure-systemd\n' "$(pacman -Q "$MICROCODE_PACKAGE")"
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
  (($# == 0)) || die "Unknown argument: $1"
  require_root
  require_commands awk grep pacman
  require_arch_systemd
  [[ -d /boot ]] || die "/boot is unavailable."
  validate_cpu_vendor
  show_plan
  confirm_installation
  install_microcode
  validate_microcode
  show_result
}

main "$@"
