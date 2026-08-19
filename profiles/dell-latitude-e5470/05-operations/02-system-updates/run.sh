#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly SNAPPER_CONFIG="root"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Runs a supervised full Arch Linux system upgrade wrapped in a Snapper pre/post pair.
This script intentionally does not answer pacman prompts automatically.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

show_plan() {
  printf '\nWeekly system update\n--------------------\n\n'
  printf 'This operation will:\n'
  printf '  - create a Snapper pre snapshot of the root filesystem\n'
  printf '  - run a full Arch Linux upgrade with pacman -Syu\n'
  printf '  - create the matching Snapper post snapshot after pacman succeeds\n'
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

create_pre_snapshot() {
  local snapshot_id
  snapshot_id="$(snapper -c "$SNAPPER_CONFIG" create \
    --type pre \
    --print-number \
    --description "weekly-system-update" \
    --userdata "class=maintenance")"

  [[ "$snapshot_id" =~ ^[0-9]+$ ]] || die "Snapper did not return a valid pre snapshot number."
  printf '%s\n' "$snapshot_id"
}

create_post_snapshot() {
  local pre_snapshot_id="$1"
  snapper -c "$SNAPPER_CONFIG" create \
    --type post \
    --pre-number "$pre_snapshot_id" \
    --description "weekly-system-update" \
    --userdata "class=maintenance"
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
    log_warn "Review the files listed above before considering maintenance complete."
  fi
}

show_result() {
  local pre_snapshot_id="$1"
  printf '\nSystem update command completed successfully.\n\n'
  printf 'Snapper maintenance pair created from pre snapshot: %s\n\n' "$pre_snapshot_id"
  printf 'Required follow-up:\n'
  printf '  - review any package-manager interventions shown above\n'
  printf '  - run the health-check step after the update\n'
  printf '  - investigate regressions before cleanup or maintenance completion\n\n'
  printf 'Next step:\n  03-health-checks\n'
}

main() {
  local pre_snapshot_id

  require_root
  require_commands find pacman snapper
  require_arch_systemd
  parse_arguments "$@"

  if ! snapper -c "$SNAPPER_CONFIG" get-config >/dev/null 2>&1; then
    die "Snapper configuration '$SNAPPER_CONFIG' is unavailable. Run 04-snapshots-and-retention before system updates."
  fi

  show_plan
  confirm_update

  pre_snapshot_id="$(create_pre_snapshot)"
  log_info "Created Snapper pre snapshot ${pre_snapshot_id}."

  log_info "Running supervised full system upgrade."
  pacman -Syu

  create_post_snapshot "$pre_snapshot_id"
  log_info "Created matching Snapper post snapshot for ${pre_snapshot_id}."

  report_configuration_interventions
  show_result "$pre_snapshot_id"
}

main "$@"
