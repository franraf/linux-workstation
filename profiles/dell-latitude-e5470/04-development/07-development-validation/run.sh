#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"

source "${REPO_ROOT}/scripts/lib/logging.sh"

setup_error_trap "$SCRIPT_NAME"

main() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run development validation as the normal user, not root."

  log_info "Running static development source validation."
  bash "${REPO_ROOT}/tests/development/static-artifacts.sh"

  log_info "Running development runtime validation."
  bash "${REPO_ROOT}/tests/development/runtime-state.sh"

  printf '\nDevelopment phase automated gate passed.\n'
  printf 'Manual validation is required on a new or rebuilt workstation; the current validated baseline is recorded in phase.yaml.\n'
}

main "$@"
