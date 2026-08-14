#!/usr/bin/env bash
set -Eeuo pipefail
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly PROFILE_ROOT="${REPO_ROOT}/profiles/dell-latitude-e5470"
readonly PROFILE_FILE="${PROFILE_ROOT}/profile.yaml"
source "${REPO_ROOT}/scripts/lib/manifest.sh"
source "${REPO_ROOT}/scripts/lib/state.sh"
pass_count=0; fail_count=0
pass() { printf '[PASS] %s\n' "$*"; ((pass_count += 1)); }
fail() { printf '[FAIL] %s\n' "$*" >&2; ((fail_count += 1)); }
for script in "${REPO_ROOT}/scripts/workstation" "${REPO_ROOT}/scripts/lib/manifest.sh" "${REPO_ROOT}/scripts/lib/state.sh"; do bash -n "$script" && pass "Bash syntax: ${script#${REPO_ROOT}/}" || fail "Bash syntax: ${script#${REPO_ROOT}/}"; done
mapfile -t phases < <(manifest_profile_phases "$PROFILE_FILE")
expected_phases=(01-installation 02-system 03-desktop 04-development 05-operations 06-security)
[[ "${phases[*]}" == "${expected_phases[*]}" ]] && pass "Profile phase order matches expected roadmap order" || fail "Profile phase order differs: ${phases[*]}"
for phase in 01-installation 02-system 03-desktop 04-development; do
  phase_file="${PROFILE_ROOT}/${phase}/phase.yaml"
  [[ -f "$phase_file" ]] && pass "Implemented phase manifest exists: $phase" || fail "Implemented phase manifest missing: $phase"
  phase_status="$(manifest_phase_field "$phase_file" status)"
  [[ "$phase_status" == validated ]] && pass "Validated phase status: $phase" || fail "Unexpected phase status for $phase: ${phase_status:-missing}"
done
for phase in 05-operations 06-security; do [[ ! -f "${PROFILE_ROOT}/${phase}/phase.yaml" ]] && pass "Future phase remains planned only: $phase" || pass "Future phase already has a manifest: $phase"; done
mapfile -t development_steps < <(manifest_phase_steps "${PROFILE_ROOT}/04-development/phase.yaml")
[[ "${development_steps[0]:-}" == 01-version-control ]] && pass "Development first step resolved" || fail "Development first step resolution"
[[ "${development_steps[-1]:-}" == 07-development-validation ]] && pass "Development final step resolved" || fail "Development final step resolution"
entrypoint="$(manifest_step_field "${PROFILE_ROOT}/04-development/phase.yaml" 07-development-validation entrypoint)"
[[ "$entrypoint" == 07-development-validation/run.sh ]] && pass "Validation entrypoint resolved" || fail "Validation entrypoint resolution: $entrypoint"
mode="$(manifest_step_field "${PROFILE_ROOT}/04-development/phase.yaml" 07-development-validation mode)"
[[ "$mode" == validation ]] && pass "Validation mode resolved" || fail "Validation mode resolution: $mode"
plan_output="$("${REPO_ROOT}/scripts/workstation" run-phase 04-development --plan)"
[[ "$plan_output" == *01-version-control* && "$plan_output" == *07-development-validation* ]] && pass "Phase plan includes first and final development steps" || fail "Phase plan output is incomplete"
resume_output="$("${REPO_ROOT}/scripts/workstation" run-phase 04-development --from 05-cli-tools --plan)"
[[ "$resume_output" != *01-version-control* && "$resume_output" == *05-cli-tools* && "$resume_output" == *07-development-validation* ]] && pass "Phase resume plan starts from the requested step" || fail "Phase resume planning failed"
if "${REPO_ROOT}/scripts/workstation" run-phase 04-development --from not-a-step --plan >/dev/null 2>&1; then fail "Unknown resume step should be rejected"; else pass "Unknown resume step is rejected"; fi
status_output="$("${REPO_ROOT}/scripts/workstation" status)"
[[ "$status_output" == *"01-installation          validated"* && "$status_output" == *"04-development           validated"* ]] && pass "Status reports validated implemented phases" || fail "Status does not report validated phase state"
[[ "$status_output" == *"05-operations            planned"* && "$status_output" == *"Next phase: 05-operations (planned)"* ]] && pass "Status identifies the next planned phase" || fail "Status does not identify the next planned phase"
bootstrap_output="$("${REPO_ROOT}/scripts/workstation" bootstrap)"
[[ "$bootstrap_output" == *"Profile:    dell-latitude-e5470"* ]] && pass "Bootstrap auto-discovers the single repository profile" || fail "Bootstrap profile discovery failed"
[[ "$bootstrap_output" == *"No execution will be attempted."* ]] && pass "Bootstrap refuses execution for a planned-only phase" || fail "Bootstrap should not execute a planned-only phase"

# Persistent state tests use an isolated XDG state directory and never touch real user state.
test_state_home="$(mktemp -d)"
trap 'rm -rf "$test_state_home"' EXIT
export XDG_STATE_HOME="$test_state_home"
state_path="$(state_file_for_profile dell-latitude-e5470)"
[[ "$state_path" == "$test_state_home/linux-workstation/dell-latitude-e5470/execution.state" ]] && pass "State uses XDG state hierarchy outside repository" || fail "Unexpected state path: $state_path"
state_write dell-latitude-e5470 04-development 05-cli-tools 06-ai-tooling interrupted
[[ -f "$state_path" ]] && pass "Persistent state record can be written" || fail "Persistent state record was not written"
[[ "$(state_read_field "$state_path" next_step)" == 06-ai-tooling ]] && pass "Persistent next step can be read" || fail "Persistent next step read failed"
execution_output="$("${REPO_ROOT}/scripts/workstation" execution-status)"
[[ "$execution_output" == *"Next step:           06-ai-tooling"* ]] && pass "Execution status reports persisted resume point" || fail "Execution status output is incorrect"
resume_plan="$("${REPO_ROOT}/scripts/workstation" resume --plan)"
[[ "$resume_plan" == *"Resume:  06-ai-tooling"* && "$resume_plan" == *06-ai-tooling* && "$resume_plan" == *07-development-validation* ]] && pass "Resume plan starts at persisted first uncompleted step" || fail "Persisted resume planning failed"
state_write dell-latitude-e5470 04-development 05-cli-tools not-a-step interrupted
if "${REPO_ROOT}/scripts/workstation" resume --plan >/dev/null 2>&1; then fail "Stale persisted step should be rejected"; else pass "Stale persisted step is rejected"; fi
state_clear dell-latitude-e5470
[[ ! -e "$state_path" ]] && pass "Execution state can be cleared" || fail "Execution state clear failed"
case "$state_path" in "${REPO_ROOT}"/*) fail "State file must not live inside repository" ;; *) pass "State file is outside repository" ;; esac

printf '\nAutomation runner static summary\nPassed: %d\nFailed: %d\n' "$pass_count" "$fail_count"
((fail_count == 0))
