
```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly MICROCODE_PACKAGE="intel-ucode"
readonly MICROCODE_IMAGE="/boot/intel-ucode.img"

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

This script installs and validates Intel CPU microcode support.

Package:
  ${MICROCODE_PACKAGE}

Expected boot image:
  ${MICROCODE_IMAGE}
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    lscpu
    pacman
    stat
    awk
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

  [[ -d /boot ]] ||
    die "/boot is unavailable."
}

validate_cpu_vendor() {
  local vendor

  vendor="$(
    lscpu |
      awk -F: '
        /^Vendor ID:/ {
          gsub(/^[[:space:]]+/, "", $2)
          print $2
          exit
        }
      '
  )"

  [[ "$vendor" == "GenuineIntel" ]] ||
    die "Expected an Intel CPU, found vendor: ${vendor:-unknown}"
}

show_plan() {
  cat <<EOF

Microcode configuration
-----------------------

CPU vendor: Intel
Package:    ${MICROCODE_PACKAGE}
Image:      ${MICROCODE_IMAGE}

The package will be installed if missing and validated afterwards.
EOF
}

confirm_installation() {
  local confirmation

  printf '\nType MICROCODE to continue: '
  read -r confirmation

  [[ "$confirmation" == "MICROCODE" ]] ||
    die "Microcode installation was not authorized."
}

install_microcode() {
  if pacman -Q "$MICROCODE_PACKAGE" >/dev/null 2>&1; then
    log "${MICROCODE_PACKAGE} is already installed."
    return
  fi

  log "Installing ${MICROCODE_PACKAGE}."

  pacman \
    --sync \
    --needed \
    "$MICROCODE_PACKAGE"
}

validate_package() {
  pacman -Q "$MICROCODE_PACKAGE" >/dev/null 2>&1 ||
    die "${MICROCODE_PACKAGE} is not installed."
}

validate_microcode_image() {
  [[ -f "$MICROCODE_IMAGE" ]] ||
    die "Microcode image is missing: $MICROCODE_IMAGE"

  [[ -s "$MICROCODE_IMAGE" ]] ||
    die "Microcode image is empty: $MICROCODE_IMAGE"

  [[ "$(stat -c '%U:%G' "$MICROCODE_IMAGE")" == "root:root" ]] ||
    warn "Unexpected ownership for $MICROCODE_IMAGE."
}

validate_boot_entry_reference() {
  local entries_directory="/boot/loader/entries"

  [[ -d "$entries_directory" ]] ||
    die "systemd-boot entry directory is missing."

  if ! grep -Rqs \
    "initrd[[:space:]]\+${MICROCODE_IMAGE#/boot}" \
    "$entries_directory"; then
    die "No systemd-boot entry references ${MICROCODE_IMAGE#/boot}."
  fi
}

show_result() {
  printf '\nIntel microcode support validated successfully.\n\n'

  printf 'Package:\n'
  printf '  %s\n' "$(pacman -Q "$MICROCODE_PACKAGE")"

  printf '\nImage:\n'
  printf '  %s\n' "$MICROCODE_IMAGE"

  printf '\nNext step:\n'
  printf '  04-configure-systemd\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_cpu_vendor
  show_plan
  confirm_installation
  install_microcode
  validate_package
  validate_microcode_image
  validate_boot_entry_reference
  show_result
}

main "$@"
```
