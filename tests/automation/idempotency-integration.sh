#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly REPO_ROOT

pass_count=0
fail_count=0
pass() {
  printf '[PASS] %s\n' "$*"
  ((pass_count += 1))
}
fail() {
  printf '[FAIL] %s\n' "$*" >&2
  ((fail_count += 1))
}

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

mkdir -p \
  "$workdir/scripts/lib" \
  "$workdir/profiles/test-profile/01-idempotent/01-configure" \
  "$workdir/profiles/test-profile/01-idempotent/02-validation" \
  "$workdir/state" \
  "$workdir/target"

cp "$REPO_ROOT/scripts/workstation" "$workdir/scripts/workstation"
cp "$REPO_ROOT/scripts/lib/manifest.sh" "$workdir/scripts/lib/manifest.sh"
cp "$REPO_ROOT/scripts/lib/state.sh" "$workdir/scripts/lib/state.sh"
chmod +x "$workdir/scripts/workstation"

cat >"$workdir/profiles/test-profile/profile.yaml" <<'EOF'
automation:
  phases:
    - 01-idempotent
EOF

cat >"$workdir/profiles/test-profile/01-idempotent/phase.yaml" <<'EOF'
phase:
  id: 01-idempotent
  status: in-progress
execution:
  order:
    - 01-configure
    - 02-validation
steps:
  01-configure:
    mode: validation
    entrypoint: 01-configure/run.sh
  02-validation:
    mode: validation
    entrypoint: 02-validation/run.sh
validation:
  final_step: 02-validation
  required_before_next_phase: true
EOF

cat >"$workdir/profiles/test-profile/01-idempotent/01-configure/run.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
mkdir -p "${TEST_TARGET}"
printf '%s\n' 'managed=true' > "${TEST_TARGET}/workstation.conf"
printf '%s\n' 'configure' >> "${TEST_EXECUTION_LOG}"
EOF

cat >"$workdir/profiles/test-profile/01-idempotent/02-validation/run.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ "$(cat "${TEST_TARGET}/workstation.conf")" == 'managed=true' ]]
printf '%s\n' 'validate' >> "${TEST_EXECUTION_LOG}"
EOF

chmod +x "$workdir"/profiles/test-profile/01-idempotent/*/run.sh

export XDG_STATE_HOME="$workdir/state"
export TEST_TARGET="$workdir/target"
export TEST_EXECUTION_LOG="$workdir/execution.log"
runner="$workdir/scripts/workstation"
state_file="$XDG_STATE_HOME/linux-workstation/test-profile/execution.state"

"$runner" run-phase 01-idempotent --profile test-profile >/dev/null
[[ ! -e "$state_file" ]] && pass "First successful phase run clears execution state" || fail "Execution state remained after first run"

first_checksum="$(sha256sum "$TEST_TARGET/workstation.conf" | awk '{print $1}')"
first_content="$(cat "$TEST_TARGET/workstation.conf")"
[[ "$first_content" == 'managed=true' ]] && pass "First run converges target configuration" || fail "First run produced unexpected configuration"

"$runner" run-phase 01-idempotent --profile test-profile >/dev/null
[[ ! -e "$state_file" ]] && pass "Second successful phase run also clears execution state" || fail "Execution state remained after second run"

second_checksum="$(sha256sum "$TEST_TARGET/workstation.conf" | awk '{print $1}')"
second_content="$(cat "$TEST_TARGET/workstation.conf")"
[[ "$second_checksum" == "$first_checksum" ]] && pass "Second run leaves managed file byte-identical" || fail "Managed file changed on second run"
[[ "$second_content" == "$first_content" ]] && pass "Second run preserves converged target state" || fail "Target state differs after second run"

mapfile -t executed <"$TEST_EXECUTION_LOG"
expected=(configure validate configure validate)
[[ "${executed[*]}" == "${expected[*]}" ]] && pass "Runner safely re-executes idempotent steps and post-gate" || fail "Unexpected execution sequence: ${executed[*]}"

plan_output="$("$runner" run-phase 01-idempotent --plan --profile test-profile)"
[[ "$plan_output" == *'[PRE-GATE] manifest contract valid'* && "$plan_output" == *'[POST-GATE] 02-validation'* ]] && pass "Idempotent phase retains pre/post gate contract" || fail "Gate contract missing from idempotency plan"

printf '\nIdempotency integration summary\n'
printf 'Passed: %d\nFailed: %d\n' "$pass_count" "$fail_count"

((fail_count == 0))
