#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly SOURCE_FILE="${REPO_ROOT}/system/systemd/zram/10-linux-workstation.conf"
readonly CONFIG_FILE="/etc/systemd/zram-generator.conf.d/10-linux-workstation.conf"
readonly ZRAM_PACKAGE="zram-generator"
readonly ZRAM_DEVICE="/dev/zram0"
readonly ZRAM_UNIT="systemd-zram-setup@zram0.service"
readonly ZRAM_SWAP_UNIT="dev-zram0.swap"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/system-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  printf 'Usage:\n  sudo ./%s\n\nCanonical source:\n  %s\n' "$SCRIPT_NAME" "$SOURCE_FILE"
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
  printf '\nType ZRAM to apply the configuration: '
  read -r confirmation
  [[ "$confirmation" == "ZRAM" ]] || die "ZRAM configuration was not authorized."
}

main() {
  require_root
  require_commands cmp pacman swapon systemctl zramctl awk xargs
  require_arch_systemd
  require_system_config_commands
  parse_arguments "$@"

  if ! pacman -Q "$ZRAM_PACKAGE" >/dev/null 2>&1; then
    log_info "Installing ${ZRAM_PACKAGE}."
    pacman -S --needed "$ZRAM_PACKAGE"
  fi

  [[ -x /usr/lib/systemd/system-generators/zram-generator ]] || die "zram-generator executable is unavailable."

  printf '\nZRAM configuration\n------------------\n\nSource:\n  %s\n\nDestination:\n  %s\n' "$SOURCE_FILE" "$CONFIG_FILE"
  confirm_configuration

  install_system_file "$SOURCE_FILE" "$CONFIG_FILE"
  validate_system_file_matches "$SOURCE_FILE" "$CONFIG_FILE"

  systemctl daemon-reload
  systemctl restart "$ZRAM_UNIT"
  systemctl start "$ZRAM_SWAP_UNIT"

  systemctl is-active --quiet "$ZRAM_UNIT" || die "${ZRAM_UNIT} is not active."
  systemctl is-active --quiet "$ZRAM_SWAP_UNIT" || die "${ZRAM_SWAP_UNIT} is not active."
  [[ -b "$ZRAM_DEVICE" ]] || die "ZRAM device was not created: $ZRAM_DEVICE"

  local algorithm
  local disksize
  local priority

  algorithm="$(zramctl --noheadings --output ALGORITHM "$ZRAM_DEVICE" | xargs)"
  disksize="$(zramctl --bytes --noheadings --output DISKSIZE "$ZRAM_DEVICE" | xargs)"
  priority="$(swapon --noheadings --show=NAME,PRIO --raw | awk -v device="$ZRAM_DEVICE" '$1 == device { print $2; exit }')"

  [[ "$algorithm" == "zstd" ]] || die "Unexpected ZRAM compression algorithm: $algorithm"
  [[ "$disksize" =~ ^[0-9]+$ ]] && ((disksize > 0)) || die "Invalid ZRAM device size."
  [[ "$priority" == "100" ]] || die "Unexpected ZRAM swap priority: ${priority:-unknown}"

  printf '\nZRAM configured successfully.\n\nNext step:\n  08-configure-trim\n'
}

main "$@"
