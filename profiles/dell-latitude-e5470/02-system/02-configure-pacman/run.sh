#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly PACMAN_CONFIG="/etc/pacman.conf"
readonly PARALLEL_DOWNLOADS="5"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  printf 'Usage:\n  sudo ./%s\n' "$SCRIPT_NAME"
}

validate_configuration_file() {
  [[ -f "$PACMAN_CONFIG" && -r "$PACMAN_CONFIG" && -w "$PACMAN_CONFIG" ]] || die "pacman.conf is unavailable or not writable."
  grep -Fxq '[options]' "$PACMAN_CONFIG" || die "Pacman configuration does not contain an [options] section."
  grep -Eq '^\[core\]$' "$PACMAN_CONFIG" || die "Core repository configuration is missing."
  grep -Eq '^\[extra\]$' "$PACMAN_CONFIG" || die "Extra repository configuration is missing."
}

show_plan() {
  printf '\nPacman configuration\n--------------------\n\nFile:\n  %s\n\nOptions:\n  Color\n  VerbosePkgLists\n  CheckSpace\n  ParallelDownloads = %s\n' "$PACMAN_CONFIG" "$PARALLEL_DOWNLOADS"
}

confirm_configuration() {
  local confirmation
  printf '\nType PACMAN to apply the configuration: '
  read -r confirmation
  [[ "$confirmation" == "PACMAN" ]] || die "Pacman configuration was not authorized."
}

enable_boolean_option() {
  local option="$1"
  local count
  count="$(grep -Ec "^[#[:space:]]*${option}[[:space:]]*$" "$PACMAN_CONFIG" || true)"
  ((count == 1)) || die "Expected exactly one default definition for $option, found: $count"
  sed -Ei "s|^[#[:space:]]*${option}[[:space:]]*$|${option}|" "$PACMAN_CONFIG"
}

configure_parallel_downloads() {
  local count
  count="$(grep -Ec '^[#[:space:]]*ParallelDownloads[[:space:]]*=' "$PACMAN_CONFIG" || true)"
  ((count == 1)) || die "Expected exactly one ParallelDownloads definition, found: $count"
  sed -Ei "s|^[#[:space:]]*ParallelDownloads[[:space:]]*=.*$|ParallelDownloads = ${PARALLEL_DOWNLOADS}|" "$PACMAN_CONFIG"
}

configure_pacman() {
  enable_boolean_option Color
  enable_boolean_option VerbosePkgLists
  enable_boolean_option CheckSpace
  configure_parallel_downloads
}

validate_options() {
  grep -Fxq 'Color' "$PACMAN_CONFIG" || die "Color is not enabled."
  grep -Fxq 'VerbosePkgLists' "$PACMAN_CONFIG" || die "VerbosePkgLists is not enabled."
  grep -Fxq 'CheckSpace' "$PACMAN_CONFIG" || die "CheckSpace is not enabled."
  grep -Eq "^ParallelDownloads[[:space:]]*=[[:space:]]*${PARALLEL_DOWNLOADS}[[:space:]]*$" "$PACMAN_CONFIG" || die "ParallelDownloads is incorrect."
  pacman --config "$PACMAN_CONFIG" -Sp pacman >/dev/null || die "Pacman could not parse its configuration."
}

show_result() {
  printf '\nPacman configured successfully.\n\nNext step:\n  03-install-microcode\n'
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && {
    usage
    exit 0
  }
  (($# == 0)) || die "Unknown argument: $1"
  require_root
  require_commands grep pacman sed
  require_arch_systemd
  validate_configuration_file
  show_plan
  confirm_configuration
  configure_pacman
  validate_options
  show_result
}

main "$@"
