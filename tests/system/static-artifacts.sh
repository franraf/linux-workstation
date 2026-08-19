#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly REPO_ROOT
readonly PROFILE_ROOT="${REPO_ROOT}/profiles/dell-latitude-e5470/02-system"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}
pass() { printf '[PASS] %s\n' "$*"; }

require_file() {
  local path="$1"
  [[ -s "$path" ]] || fail "Required source is missing or empty: ${path#${REPO_ROOT}/}"
  pass "Source exists: ${path#${REPO_ROOT}/}"
}

for step in {01..12}; do
  run_file="$(find "$PROFILE_ROOT" -maxdepth 2 -path "*/${step}-*/run.sh" -print -quit)"
  [[ -n "$run_file" ]] || fail "run.sh not found for step $step"
  bash -n "$run_file" || fail "Bash syntax failed: ${run_file#${REPO_ROOT}/}"
  pass "Bash syntax: ${run_file#${REPO_ROOT}/}"
done

for library in logging requirements packages installation storage user-config system-config; do
  require_file "${REPO_ROOT}/scripts/lib/${library}.sh"
  bash -n "${REPO_ROOT}/scripts/lib/${library}.sh" || fail "Library syntax failed: $library"
done

require_file "${REPO_ROOT}/packages/system/base-workstation.txt"
require_file "${REPO_ROOT}/packages/system/services.txt"
require_file "${REPO_ROOT}/system/systemd/10-linux-workstation.conf"
require_file "${REPO_ROOT}/system/systemd/timesyncd/10-linux-workstation.conf"
require_file "${REPO_ROOT}/system/systemd/journald/10-linux-workstation.conf"
require_file "${REPO_ROOT}/system/systemd/zram/10-linux-workstation.conf"
require_file "${REPO_ROOT}/system/openssh/10-linux-workstation.conf"
require_file "${REPO_ROOT}/tests/system/runtime-state.sh"
require_file "${REPO_ROOT}/tests/repository/phase-consistency.sh"
bash -n "${REPO_ROOT}/tests/system/runtime-state.sh" || fail "Runtime validator syntax failed"
bash -n "${REPO_ROOT}/tests/repository/phase-consistency.sh" || fail "Cross-phase validator syntax failed"
pass "Validation script syntax"

bash "${REPO_ROOT}/tests/repository/phase-consistency.sh"

local_package_file="${PROFILE_ROOT}/11-install-base-packages/packages.txt"
if [[ -e "$local_package_file" ]]; then
  printf '[WARN] Legacy profile-local package file still exists but is not consumed: %s\n' "${local_package_file#${REPO_ROOT}/}" >&2
else
  pass "Legacy profile-local package file is absent"
fi

printf '\nSystem static source validation completed successfully.\n'
