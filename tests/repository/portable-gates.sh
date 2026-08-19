#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly REPO_ROOT

run_gate() {
  local name="$1"
  local script="$2"

  printf '\n============================================================\n'
  printf 'Portable gate: %s\n' "$name"
  printf '============================================================\n\n'
  bash "${REPO_ROOT}/${script}"
}

run_gate "Repository phase consistency" "tests/repository/phase-consistency.sh"
run_gate "Installation static artifacts" "tests/installation/static-artifacts.sh"
run_gate "System static artifacts" "tests/system/static-artifacts.sh"
run_gate "Development static artifacts" "tests/development/static-artifacts.sh"
run_gate "Shell quality" "tests/repository/shell-quality-audit.sh"

printf '\n============================================================\n'
printf 'Portable gate: Repository automation\n'
printf '============================================================\n\n'
make -C "$REPO_ROOT" validate-automation

printf '\nAll portable repository gates passed.\n'
