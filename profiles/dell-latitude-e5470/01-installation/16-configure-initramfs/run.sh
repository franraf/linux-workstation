#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SOURCE_CONFIG="${REPO_ROOT}/system/mkinitcpio/10-linux-workstation-intel.conf"
readonly CONFIG_DIRECTORY="/etc/mkinitcpio.conf.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "$SOURCE_CONFIG"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Installs the canonical mkinitcpio configuration and regenerates all presets.

Source:
  ${SOURCE_CONFIG}

Target:
  ${CONFIG_FILE}
EOF
}

validate_execution_context() {
  require_arch_linux
  [[ -s /etc/fstab ]] || die "The installed-system fstab is missing or empty."
  [[ -f /etc/vconsole.conf ]] || die "/etc/vconsole.conf is missing."
  grep -Fxq 'KEYMAP=br-abnt2' /etc/vconsole.conf || die "Expected KEYMAP=br-abnt2 in /etc/vconsole.conf."
}

validate_required_packages() {
  local package
  for package in linux mkinitcpio cryptsetup systemd kbd; do
    pacman -Q "$package" >/dev/null 2>&1 || die "Required package is not installed: $package"
  done
}

validate_kernel_preset() {
  [[ -f /etc/mkinitcpio.d/linux.preset ]] || die "Linux mkinitcpio preset is missing."
  ! grep -Eq '^[[:space:]]*ALL_config=' /etc/mkinitcpio.d/linux.preset ||
    die "linux.preset defines ALL_config and may ignore drop-in files."
}

validate_hooks_available() {
  local hook
  for hook in "${HOOKS[@]}"; do
    [[ -f "/usr/lib/initcpio/install/${hook}" ]] || die "Required mkinitcpio hook is unavailable: $hook"
  done
}

validate_modules_available() {
  local kernel_version
  local module
  kernel_version="$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -n 1)"
  [[ -n "$kernel_version" ]] || die "No installed kernel module tree was found."

  for module in "${MODULES[@]}"; do
    modinfo --set-version "$kernel_version" "$module" >/dev/null 2>&1 ||
      die "Required kernel module is unavailable: $module"
  done
}

show_plan() {
  printf '\nInitramfs configuration\n'
  printf '%s\n\n' '-----------------------'
  printf 'Source:\n  %s\n\n' "$SOURCE_CONFIG"
  printf 'Target:\n  %s\n\n' "$CONFIG_FILE"
  printf 'Modules:\n  - %s\n' "${MODULES[@]}"
  printf '\nHooks:\n  - %s\n' "${HOOKS[@]}"
}

confirm_configuration() {
  local confirmation
  printf '\nType INITRAMFS to apply the configuration: '
  read -r confirmation
  [[ "$confirmation" == "INITRAMFS" ]] || die "Initramfs configuration was not authorized."
}

install_configuration() {
  install --directory --owner root --group root --mode 0755 "$CONFIG_DIRECTORY"
  install --owner root --group root --mode 0644 "$SOURCE_CONFIG" "$CONFIG_FILE"
}

validate_configuration_file() {
  [[ -s "$CONFIG_FILE" ]] || die "mkinitcpio drop-in configuration was not created."
  [[ "$(stat -c '%U:%G' "$CONFIG_FILE")" == "root:root" ]] || die "mkinitcpio configuration ownership is incorrect."
  [[ "$(stat -c '%a' "$CONFIG_FILE")" == "644" ]] || die "mkinitcpio configuration permissions are incorrect."
  bash -n "$CONFIG_FILE" || die "mkinitcpio configuration contains invalid shell syntax."
  cmp -s "$SOURCE_CONFIG" "$CONFIG_FILE" || die "Installed mkinitcpio configuration differs from the canonical source."
}

generate_initramfs() {
  log_info "Generating all mkinitcpio preset images."
  mkinitcpio -P
}

locate_initramfs_image() {
  local image
  image="$(awk -F= '/^[[:space:]]*default_image=/ { value=$2; gsub(/^[[:space:]\"]+|[[:space:]\"]+$/, "", value); print value; exit }' /etc/mkinitcpio.d/linux.preset)"
  [[ -n "$image" ]] || image="/boot/initramfs-linux.img"
  printf '%s\n' "$image"
}

validate_generated_image() {
  local image
  image="$(locate_initramfs_image)"
  [[ -s "$image" ]] || die "Generated initramfs image is missing or empty: $image"
  lsinitcpio "$image" >/dev/null || die "Generated initramfs image could not be inspected."
}

validate_initramfs_contents() {
  local image
  local contents
  image="$(locate_initramfs_image)"
  contents="$(lsinitcpio "$image")"

  grep -Eq '(^|/)systemd-cryptsetup$' <<<"$contents" || die "systemd-cryptsetup was not included in the initramfs."
  grep -Eq '(^|/)systemd-cryptsetup-generator$' <<<"$contents" || die "systemd-cryptsetup-generator was not included in the initramfs."
  grep -Eq '(^|/)i915\.ko(\.(xz|zst|gz))?$' <<<"$contents" || die "The i915 module was not included in the initramfs."
  grep -Eq '(^|/)etc/vconsole\.conf$' <<<"$contents" || die "/etc/vconsole.conf was not included in the initramfs."
}

show_result() {
  printf '\nInitramfs configured successfully.\n\n'
  printf 'Configuration:\n  %s\n' "$CONFIG_FILE"
  printf '\nGenerated image:\n  %s\n' "$(locate_initramfs_image)"
  printf '\nNext step:\n  17-install-bootloader\n'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
  (($# == 0)) || die "Unknown argument: $1"

  require_root
  require_commands awk bash cmp find grep install lsinitcpio mkinitcpio modinfo pacman sort stat tail
  validate_execution_context
  validate_required_packages
  validate_kernel_preset
  validate_hooks_available
  validate_modules_available
  show_plan
  confirm_configuration
  install_configuration
  validate_configuration_file
  generate_initramfs
  validate_generated_image
  validate_initramfs_contents
  show_result
}

main "$@"
