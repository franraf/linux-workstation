#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/desktop/graphics-intel-amd.txt"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Installs and validates the graphics stack for the Dell Latitude E5470.

Package source:
  ${PACKAGE_FILE}
EOF
}

validate_hardware() {
  log_info "Validating graphics hardware."

  lspci -nnk | grep -A3 -Ei 'VGA|3D|Display' || die "No graphics device was detected."

  lspci -nnk | grep -qi 'Intel Corporation' || die "Expected Intel integrated GPU was not detected."
  lspci -nnk | grep -Eqi 'AMD|ATI' || log_warn "AMD dedicated GPU was not detected; continuing because it is optional."
}

show_plan() {
  printf '\nGraphics stack installation\n'
  printf '%s\n\n' '---------------------------'
  printf 'Package file:\n  %s\n\n' "$PACKAGE_FILE"
  printf 'Declared packages:\n'
  printf '  - %s\n' "${PACKAGES[@]}"

  printf '\nPackages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_installation() {
  ((${#MISSING_PACKAGES[@]} > 0)) || return

  local confirmation
  printf '\nType PACKAGES to install the missing graphics packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] || die "Graphics package installation was not authorized."
}

validate_kernel_drivers() {
  log_info "Validating kernel graphics drivers."

  lsmod | grep -q '^i915' || die "Intel i915 kernel module is not loaded."

  if lspci -nnk | grep -Eqi 'AMD|ATI'; then
    lsmod | grep -q '^amdgpu' || log_warn "AMD GPU is present but amdgpu is not currently loaded."
  fi
}

validate_graphics_tools() {
  require_commands glxinfo vainfo vulkaninfo

  log_info "Checking OpenGL renderer."
  glxinfo -B 2>/dev/null | sed -n '/OpenGL vendor string:/p;/OpenGL renderer string:/p;/OpenGL core profile version string:/p' || true

  log_info "Checking VA-API availability."
  vainfo >/dev/null 2>&1 || log_warn "vainfo could not initialize in the current session; validate again inside the graphical session."

  log_info "Checking Vulkan ICDs."
  vulkaninfo --summary >/dev/null 2>&1 || log_warn "vulkaninfo could not initialize in the current session; validate again inside the graphical session."
}

show_result() {
  printf '\nGraphics stack installed successfully.\n\n'
  printf 'Installed package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nNext step:\n  02-install-compositor\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  (($# == 0)) || die "Unknown argument: $1"

  require_root
  require_commands awk grep lspci lsmod pacman sed
  require_arch_systemd
  validate_hardware

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages
  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  validate_kernel_drivers
  validate_graphics_tools
  show_result
}

main "$@"
