#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Runs a supervised full Arch Linux system upgrade.
This script intentionally does not answer pacman prompts automatically.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

show_plan() {
  printf '\nWeekly system update\n--------------------\n\n'
  printf 'This operation will:\n'
  printf '  - run a full Arch Linux upgrade with pacman -Syu\n'
  printf '  - leave every pacman decision visible to the operator\n'
  printf '  - report .pacnew/.pacsave files after the upgrade\n\n'
  printf 'Health checks are a separate gate and must be run before and after this step.\n'
}

confirm_update() {
  local confirmation
  printf '\nType UPDATE to start the supervised system upgrade: '
  read -r confirmation
  [[ "$confirmation" == "UPDATE" ]] || die "System update was not authorized."
}

report_configuration_interventions() {
  local found=0
  local path

  printf '\nConfiguration interventions\n---------------------------\n\n'

  while IFS= read -r -d '' path; do
    printf '  - %s\n' "$path"
    found=1
  done < <(find /etc -xdev -type f \( -name '*.pacnew' -o -name '*.pacsave' \) -print0 2>/dev/null)

  if ((found == 0)); then
    printf '  none found under /etc\n'
  else
    warn "Review the files listed above before considering maintenance complete."
  fi
}

show_result() {
  printf '\nSystem update command completed successfully.\n\n'
  printf 'Required follow-up:\n'
  printf '  - review any package-manager interventions shown above\n'
  printf '  - run the health-check step after the update\n'
  printf '  - investigate regressions before cleanup or maintenance completion\n\n'
  printf 'Next step:\n  03-health-checks\n'
}

main() {
  require_root
  require_commands find pacman
  require_arch_systemd
  parse_arguments "$@"

  show_plan
  confirm_update

  log_info "Running supervised full system upgrade."
  pacman -Syu

  report_configuration_interventions
  show_result
}

main "$@"
