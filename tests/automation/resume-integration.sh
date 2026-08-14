#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"

pass_count=0
fail_count=0
pass() { printf '[PASS] %s\n' "$*"; ((pass_count += 1)); }
fail() { printf '[FAIL] %s\n' "$*" >&2; ((fail_count += 1)); }

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

mkdir -p \
  "$workdir/scripts/lib" \
  "$workdir/profiles/test-profile/01-test/01-success" \
  "$workdir/profiles/test-profile/01-test/02-fail-once" \
  "$workdir/profiles/test-profile/01-test/03-success" \
  "$workdir/state"

cp "$REPO_ROOT/scripts/workstation" "$workdir/scripts/workstation"
cp "$REPO_ROOT/scripts/lib/manifest.sh" "$workdir/scripts/lib/manifest.sh"
cp "$REPO_ROOT/scripts/lib/state.sh" "$workdir/scripts/lib/state.sh"
chmod +x "$workdir/scripts/workstation"

cat > "$workdir/profiles/test-profile/profile.yaml" <<'EOF'
automation:
  phases:
    - 01-test
EOF

cat > "$workdir/profiles/test-profile/01-test/phase.yaml" <<'EOF'
phase:
  id: 01-test
  status: in-progress
execution:
  order:
    - 01-success
    - 02-fail-once
    - 03-success
steps:
  01-success:
    mode: validation
    entrypoint: 01-success/run.sh
  02-fail-once:
    mode: validation
    entrypoint: 02-fail-once/run.sh
  03-success:
    mode: validation
    entrypoint: 03-success/run.sh
EOF

cat > "$workdir/profiles/test-profile/01-test/01-success/run.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'step-1\n' >> "${TEST_LOG}"
EOF

cat > "$workdir/profiles/test-profile/01-test/02-fail-once/run.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'step-2\n' >> "${TEST_LOG}"
if [[ ! -f "${TEST_FAIL_MARKER}" ]]; then
  touch "${TEST_FAIL_MARKER}"
  exit 42
fi
EOF

cat > "$workdir/profiles/test-profile/01-test/03-success/run.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'step-3\n' >> "${TEST_LOG}"
EOF

chmod +x "$workdir"/profiles/test-profile/01-test/*/run.sh

export XDG_STATE_HOME="$workdir/state"
export TEST_LOG="$workdir/execution.log"
export TEST_FAIL_MARKER="$workdir/fail-once.marker"
runner="$workdir/scripts/workstation"
state_file="$XDG_STATE_HOME/linux-workstation/test-profile/execution.state"

if "$runner" run-phase 01-test --profile test-profile >/dev/null 2>&1; then
  fail "Controlled phase should fail on the second step"
else
  pass "Controlled phase stops when a step fails"
fi

[[ -f "$state_file" ]] && pass "Failed phase leaves persistent execution state" || fail "Failed phase did not leave execution state"

next_step="$(awk -F= '$1 == "next_step" { print $2 }' "$state_file")"
last_completed="$(awk -F= '$1 == "last_completed_step" { print $2 }' "$state_file")"
[[ "$next_step" == "02-fail-once" ]] && pass "Resume point is the failed first uncompleted step" || fail "Unexpected resume point: $next_step"
[[ "$last_completed" == "01-success" ]] && pass "Only the successful prior step is recorded complete" || fail "Unexpected last completed step: $last_completed"

plan_output="$("$runner" resume --plan --profile test-profile)"
[[ "$plan_output" == *"Resume:  02-fail-once"* && "$plan_output" == *"02-fail-once"* && "$plan_output" == *"03-success"* ]] &&
  pass "Resume plan starts at the persisted failed step" || fail "Resume plan is incorrect"

"$runner" resume --profile test-profile >/dev/null

[[ ! -e "$state_file" ]] && pass "Successful resumed phase clears active state" || fail "State remained after successful resume"

mapfile -t executed < "$TEST_LOG"
expected=(step-1 step-2 step-2 step-3)
[[ "${executed[*]}" == "${expected[*]}" ]] &&
  pass "Resume replays only the failed step and remaining steps" || fail "Unexpected execution order: ${executed[*]}"

printf '\nResume integration summary\n'
printf 'Passed: %d\nFailed: %d\n' "$pass_count" "$fail_count"

((fail_count == 0))
