#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly ZRAM_PACKAGE="zram-generator"
readonly CONFIG_DIRECTORY="/etc/systemd/zram-generator.conf.d"
readonly CONFIG_FILE="${CONFIG_DIRECTORY}/10-linux-workstation.conf"

readonly ZRAM_DEVICE="/dev/zram0"
readonly ZRAM_UNIT="systemd-zram-setup@zram0.service"
readonly ZRAM_SWAP_UNIT="dev-zram0.swap"

readonly ZRAM_SIZE="min(ram / 2, 4096)"
readonly COMPRESSION_ALGORITHM="zstd"
readonly SWAP_PRIORITY="100"

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

This script configures compressed swap using systemd-zram-generator.

Package:
  ${ZRAM_PACKAGE}

Configuration:
  ${CONFIG_FILE}

Device:
  ${ZRAM_DEVICE}

Settings:
  zram-size = ${ZRAM_SIZE}
  compression-algorithm = ${COMPRESSION_ALGORITHM}
  swap-priority = ${SWAP_PRIORITY}
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
    swapon
    systemctl
    zramctl
    awk
    sed
    xargs
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

ZRAM configuration
------------------

Implementation:
  ${ZRAM_PACKAGE}

Configuration:
  ${CONFIG_FILE}

Device:
  ${ZRAM_DEVICE}

Size:
  ${ZRAM_SIZE}

Compression:
  ${COMPRESSION_ALGORITHM}

Swap priority:
  ${SWAP_PRIORITY}
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType ZRAM to apply the configuration: '
  read -r confirmation

  [[ "$confirmation" == "ZRAM" ]] ||
    die "ZRAM configuration was not authorized."
}

install_package() {
  if pacman -Q "$ZRAM_PACKAGE" >/dev/null 2>&1; then
    log "${ZRAM_PACKAGE} is already installed."
    return
  fi

  log "Installing ${ZRAM_PACKAGE}."

  pacman \
    --sync \
    --needed \
    "$ZRAM_PACKAGE"
}

validate_package() {
  pacman -Q "$ZRAM_PACKAGE" >/dev/null 2>&1 ||
    die "${ZRAM_PACKAGE} is not installed."

  [[ -x /usr/lib/systemd/system-generators/zram-generator ]] ||
    die "zram-generator executable is unavailable."
}

write_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
# Managed by linux-workstation.
# Profile: dell-latitude-e5470

[zram0]
zram-size = ${ZRAM_SIZE}
compression-algorithm = ${COMPRESSION_ALGORITHM}
swap-priority = ${SWAP_PRIORITY}
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
    die "ZRAM configuration file was not created."

  grep -Fxq '[zram0]' "$CONFIG_FILE" ||
    die "zram0 section is missing."

  grep -Fxq "zram-size = ${ZRAM_SIZE}" "$CONFIG_FILE" ||
    die "Unexpected zram-size configuration."

  grep -Fxq \
    "compression-algorithm = ${COMPRESSION_ALGORITHM}" \
    "$CONFIG_FILE" ||
    die "Unexpected compression algorithm."

  grep -Fxq "swap-priority = ${SWAP_PRIORITY}" "$CONFIG_FILE" ||
    die "Unexpected swap priority."
}

reload_systemd() {
  log "Reloading systemd generators."

  systemctl daemon-reload
}

activate_zram() {
  log "Starting ZRAM device."

  systemctl restart "$ZRAM_UNIT"

  log "Activating ZRAM swap"

  systemctl start "$ZRAM_SWAP_UNIT"
}

validate_setup_units() {
  systemctl is-active --quiet "$ZRAM_UNIT" ||
    die "${ZRAM_UNIT} is not active."

  systemctl is-active --quiet "$ZRAM_SWAP_UNIT" ||
    die "${ZRAM_SWAP_UNIT} is not active."
}

validate_device() {
  [[ -b "$ZRAM_DEVICE" ]] ||
    die "ZRAM device was not created: $ZRAM_DEVICE"

  local algorithm
  local disksize

  algorithm="$(
    zramctl \
      --noheadings \
      --output ALGORITHM \
      "$ZRAM_DEVICE" |
      xargs
  )"

  disksize="$(
    zramctl \
      --bytes \
      --noheadings \
      --output DISKSIZE \
      "$ZRAM_DEVICE" |
      xargs
  )"

  [[ "$algorithm" == "$COMPRESSION_ALGORITHM" ]] ||
    die "Unexpected ZRAM compression algorithm: $algorithm"

  [[ "$disksize" =~ ^[0-9]+$ ]] ||
    die "Unable to determine ZRAM device size."

  ((disksize > 0)) ||
    die "ZRAM device size is zero."
}

validate_swap() {
  local swap_entry
  local priority

  swap_entry="$(
    swapon \
      --noheadings \
      --show=NAME \
      --raw |
      grep -Fx "$ZRAM_DEVICE" ||
      true
  )"

  [[ "$swap_entry" == "$ZRAM_DEVICE" ]] ||
    die "$ZRAM_DEVICE is not active as swap."

  priority="$(
    swapon \
      --noheadings \
      --show=NAME,PRIO \
      --raw |
      awk -v device="$ZRAM_DEVICE" '
        $1 == device {
          print $2
          exit
        }
      '
  )"

  [[ "$priority" == "$SWAP_PRIORITY" ]] ||
    die "Unexpected ZRAM swap priority: ${priority:-unknown}"
}

show_result() {
  printf '\nZRAM configured successfully.\n\n'

  printf 'Configuration:\n'
  printf '  %s\n' "$CONFIG_FILE"

  printf '\nDevice:\n'
  zramctl "$ZRAM_DEVICE" |
    sed 's/^/  /'

  printf '\nSwap:\n'
  swapon --show |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  08-configure-trim\n'
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
  reload_systemd
  activate_zram
  validate_setup_units
  validate_device
  validate_swap
  show_result
}

main "$@"
