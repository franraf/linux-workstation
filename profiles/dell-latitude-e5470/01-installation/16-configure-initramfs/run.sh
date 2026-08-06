#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly CONFIG_DIRECTORY="/etc/mkinitcpio.conf.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"

readonly EXPECTED_HOOKS=(
  base
  systemd
  autodetect
  microcode
  modconf
  kms
  keyboard
  sd-vconsole
  block
  sd-encrypt
  filesystems
  fsck
)

readonly EXPECTED_MODULES=(
  i915
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
  ./$SCRIPT_NAME

This script configures mkinitcpio for:

  - systemd-based early userspace;
  - LUKS2 encrypted root;
  - Brazilian console keymap;
  - Intel integrated graphics;
  - Btrfs root filesystem.

Configuration file:

  ${CONFIG_FILE}

This script must run inside the installed Arch Linux system.
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
    lsinitcpio
    mkinitcpio
    pacman
    sed
    awk
    bash
    find
    modinfo
    mktemp
    sort
    stat
    tail
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
    die "This script must run inside the installed Arch Linux system."

  [[ -s /etc/fstab ]] ||
    die "The installed-system fstab is missing or empty."

  [[ -f /etc/vconsole.conf ]] ||
    die "/etc/vconsole.conf is missing."

  grep -Fxq 'KEYMAP=br-abnt2' /etc/vconsole.conf ||
    die "Expected KEYMAP=br-abnt2 in /etc/vconsole.conf."
}

validate_required_packages() {
  local packages=(
    linux
    mkinitcpio
    cryptsetup
    systemd
    kbd
  )

  local package

  for package in "${packages[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 ||
      die "Required package is not installed: $package"
  done
}

validate_kernel_preset() {
  [[ -f /etc/mkinitcpio.d/linux.preset ]] ||
    die "Linux mkinitcpio preset is missing."

  if grep -Eq \
    '^[[:space:]]*ALL_config=' \
    /etc/mkinitcpio.d/linux.preset; then
    die "linux.preset defines ALL_config and may ignore drop-in files."
  fi
}

validate_hooks_available() {
  local hook
  local hook_path

  for hook in "${EXPECTED_HOOKS[@]}"; do
    hook_path="/usr/lib/initcpio/install/${hook}"

    [[ -f "$hook_path" ]] ||
      die "Required mkinitcpio hook is unavailable: $hook"
  done
}

validate_modules_available() {
  local kernel_version
  local module

  kernel_version="$(
    find /usr/lib/modules \
      -mindepth 1 \
      -maxdepth 1 \
      -type d \
      -printf '%f\n' |
      sort -V |
      tail -n 1
  )"

  [[ -n "$kernel_version" ]] ||
    die "No installed kernel module tree was found."

  for module in "${EXPECTED_MODULES[@]}"; do
    modinfo \
      --set-version "$kernel_version" \
      "$module" >/dev/null 2>&1 ||
      die "Required kernel module is unavailable: $module"
  done
}

show_plan() {
  cat <<EOF

Initramfs configuration
-----------------------

Configuration file:
  ${CONFIG_FILE}

Modules:
EOF

  printf '  - %s\n' "${EXPECTED_MODULES[@]}"

  printf '\nHooks:\n'
  printf '  - %s\n' "${EXPECTED_HOOKS[@]}"

  cat <<EOF

Images will be regenerated using all installed mkinitcpio presets.
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType INITRAMFS to apply the configuration: '
  read -r confirmation

  [[ "$confirmation" == "INITRAMFS" ]] ||
    die "Initramfs configuration was not authorized."
}

write_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"

  trap 'rm -f "$temporary_file"' RETURN

  {
    printf '# Managed by linux-workstation.\n'
    printf '# Profile: dell-latitude-e5470\n\n'

    printf 'MODULES=('
    printf '%s ' "${EXPECTED_MODULES[@]}"
    printf ')\n'

    printf 'HOOKS=('
    printf '%s ' "${EXPECTED_HOOKS[@]}"
    printf ')\n'
  } >"$temporary_file"

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
    die "mkinitcpio drop-in configuration was not created."

  [[ "$(stat -c '%U:%G' "$CONFIG_FILE")" == "root:root" ]] ||
    die "mkinitcpio configuration ownership is incorrect."

  [[ "$(stat -c '%a' "$CONFIG_FILE")" == "644" ]] ||
    die "mkinitcpio configuration permissions are incorrect."

  bash -n "$CONFIG_FILE" ||
    die "mkinitcpio configuration contains invalid shell syntax."
}

read_array_from_config() {
  local variable_name=$1

  bash -c "
    source '$CONFIG_FILE'
    printf '%s\n' \"\${${variable_name}[@]}\"
  "
}

validate_configured_hooks() {
  local actual_hooks
  local expected_hooks

  actual_hooks="$(read_array_from_config HOOKS)"
  expected_hooks="$(printf '%s\n' "${EXPECTED_HOOKS[@]}")"

  [[ "$actual_hooks" == "$expected_hooks" ]] ||
    die "Configured HOOKS do not match the expected order."
}

validate_configured_modules() {
  local actual_modules
  local expected_modules

  actual_modules="$(read_array_from_config MODULES)"
  expected_modules="$(printf '%s\n' "${EXPECTED_MODULES[@]}")"

  [[ "$actual_modules" == "$expected_modules" ]] ||
    die "Configured MODULES do not match the expected values."
}

generate_initramfs() {
  log "Generating all mkinitcpio preset images."

  mkinitcpio -P
}

locate_initramfs_image() {
  local image

  image="$(
    awk -F= '
      /^[[:space:]]*default_image=/ {
        value = $2
        gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", value)
        print value
        exit
      }
    ' /etc/mkinitcpio.d/linux.preset
  )"

  if [[ -z "$image" ]]; then
    image="/boot/initramfs-linux.img"
  fi

  printf '%s\n' "$image"
}

validate_generated_image() {
  local image

  image="$(locate_initramfs_image)"

  [[ -s "$image" ]] ||
    die "Generated initramfs image is missing or empty: $image"

  lsinitcpio "$image" >/dev/null ||
    die "Generated initramfs image could not be inspected."
}

validate_initramfs_contents() {
  local image
  local contents

  image="$(locate_initramfs_image)"
  contents="$(lsinitcpio "$image")"

  grep -Eq '(^|/)systemd-cryptsetup$' <<<"$contents" ||
    die "systemd-cryptsetup was not included in the initramfs."

  grep -Eq '(^|/)systemd-cryptsetup-generator$' <<<"$contents" ||
    die "systemd-cryptsetup-generator was not included in the initramfs."

  grep -Eq '(^|/)i915\.ko(\.(xz|zst|gz))?$' <<<"$contents" ||
    die "The i915 module was not included in the initramfs."

  grep -Eq '(^|/)etc/vconsole\.conf$' <<<"$contents" ||
    die "/etc/vconsole.conf was not included in the initramfs."
}

show_result() {
  local image

  image="$(locate_initramfs_image)"

  printf '\nInitramfs configured successfully.\n\n'

  printf 'Configuration:\n'
  printf '  %s\n' "$CONFIG_FILE"

  printf '\nGenerated image:\n'
  printf '  %s\n' "$image"

  printf '\nModules:\n'
  printf '  %s\n' "${EXPECTED_MODULES[@]}"

  printf '\nHooks:\n'
  printf '  %s\n' "${EXPECTED_HOOKS[@]}"

  printf '\nNext step:\n'
  printf '  17-install-bootloader\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_required_packages
  validate_kernel_preset
  validate_hooks_available
  validate_modules_available
  show_plan
  confirm_configuration
  write_configuration
  validate_configuration_file
  validate_configured_modules
  validate_configured_hooks
  generate_initramfs
  validate_generated_image
  validate_initramfs_contents
  show_result
}

main "$@"
