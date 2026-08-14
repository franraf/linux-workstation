#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly PROFILE_ROOT="${REPO_ROOT}/profiles/dell-latitude-e5470"
readonly PROFILE_FILE="${PROFILE_ROOT}/profile.yaml"

source "${REPO_ROOT}/scripts/lib/manifest.sh"

pass_count=0
fail_count=0

pass() { printf '[PASS] %s\n' "$*"; ((pass_count += 1)); }
fail() { printf '[FAIL] %s\n' "$*" >&2; ((fail_count += 1)); }

for script in \
  "${REPO_ROOT}/scripts/workstation" \
  "${REPO_ROOT}/scripts/lib/manifest.sh"; do
  bash -n "$script" && pass "Bash syntax: ${script#${REPO_ROOT}/}" || fail "Bash syntax: ${script#${REPO_ROOT}/}"
done

mapfile -t phases < <(manifest_profile_phases "$PROFILE_FILE")
expected_phases=(01-installation 02-system 03-desktop 04-development 05-operations 06-security)

if [[ "${phases[*]}" == "${expected_phases[*]}" ]]; then
  pass "Profile phase order matches expected roadmap order"
else
  fail "Profile phase order differs: ${phases[*]}"
fi

for phase in 01-installation 02-system 03-desktop 04-development; do
  phase_file="${PROFILE_ROOT}/${phase}/phase.yaml"
  if [[ -f "$phase_file" ]]; then
    pass "Implemented phase manifest exists: $phase"
  else
    fail "Implemented phase manifest missing: $phase"
  fi

done

for phase in 05-operations 06-security; do
  if [[ ! -f "${PROFILE_ROOT}/${phase}/phase.yaml" ]]; then
    pass "Future phase remains planned only: $phase"
  else
    pass "Future phase already has a manifest: $phase"
  fi
done

mapfile -t development_steps < <(manifest_phase_steps "${PROFILE_ROOT}/04-development/phase.yaml")
[[ "${development_steps[0]:-}" == "01-version-control" ]] && pass "Development first step resolved" || fail "Development first step resolution"
[[ "${development_steps[-1]:-}" == "07-development-validation" ]] && pass "Development final step resolved" || fail "Development final step resolution"

entrypoint="$(manifest_step_field "${PROFILE_ROOT}/04-development/phase.yaml" "07-development-validation" entrypoint)"
[[ "$entrypoint" == "07-development-validation/run.sh" ]] && pass "Validation entrypoint resolved" || fail "Validation entrypoint resolution: $entrypoint"

mode="$(manifest_step_field "${PROFILE_ROOT}/04-development/phase.yaml" "07-development-validation" mode)"
[[ "$mode" == "validation" ]] && pass "Validation mode resolved" || fail "Validation mode resolution: $mode"

printf '\nAutomation runner static summary\n'
printf 'Passed: %d\nFailed: %d\n' "$pass_count" "$fail_count"

((fail_count == 0))
