#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly PROFILE_ROOT="${REPO_ROOT}/profiles/dell-latitude-e5470"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

pass() {
  printf '[PASS] %s\n' "$*"
}

validate_phase_manifest() {
  local phase_dir="$1"
  local manifest="${phase_dir}/phase.yaml"
  local relative_phase="${phase_dir#${REPO_ROOT}/}"
  local value
  local resolved

  [[ -s "$manifest" ]] || fail "Missing phase manifest: ${relative_phase}/phase.yaml"

  if head -n 1 "$manifest" | grep -q '^```'; then
    fail "Phase manifest is wrapped in a Markdown code fence: ${relative_phase}/phase.yaml"
  fi

  while IFS= read -r value; do
    [[ -n "$value" ]] || continue
    resolved="$(cd "$phase_dir" && realpath -m "$value")"
    [[ -f "$resolved" ]] || fail "Playbook reference does not exist: ${relative_phase}/$value"
  done < <(awk '/^[[:space:]]+playbook:[[:space:]]+/ { print $2 }' "$manifest")

  while IFS= read -r value; do
    [[ -n "$value" ]] || continue
    [[ -f "${phase_dir}/${value}" ]] || fail "Entrypoint does not exist: ${relative_phase}/${value}"
  done < <(awk '/^[[:space:]]+entrypoint:[[:space:]]+/ { print $2 }' "$manifest")

  pass "Manifest references are valid: ${relative_phase}/phase.yaml"
}

validate_phase_manifest "${PROFILE_ROOT}/01-installation"
validate_phase_manifest "${PROFILE_ROOT}/02-system"

printf '\nCross-phase manifest consistency validation passed.\n'
