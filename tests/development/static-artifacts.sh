#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly PROFILE_ROOT="${REPO_ROOT}/profiles/dell-latitude-e5470/04-development"

fail() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }
pass() { printf '[PASS] %s\n' "$*"; }

require_file() {
  local path="$1"
  [[ -s "$path" ]] || fail "Required source is missing or empty: ${path#${REPO_ROOT}/}"
  pass "Source exists: ${path#${REPO_ROOT}/}"
}

bash "${REPO_ROOT}/tests/repository/phase-consistency.sh"

for step in 01-version-control 02-shell-environment 03-code-editor; do
  run_file="${PROFILE_ROOT}/${step}/run.sh"
  require_file "$run_file"
  bash -n "$run_file" || fail "Bash syntax failed: ${run_file#${REPO_ROOT}/}"
  pass "Bash syntax: ${run_file#${REPO_ROOT}/}"
done

for package_file in version-control shell code-editor-runtime; do
  require_file "${REPO_ROOT}/packages/development/${package_file}.txt"
done

require_file "${REPO_ROOT}/system/development/zsh/zshenv"
require_file "${REPO_ROOT}/system/development/zsh/zshrc"
require_file "${REPO_ROOT}/system/development/starship/starship.toml"
require_file "${REPO_ROOT}/system/development/vscode/code.desktop"

for module in environment aliases completion functions integrations prompt; do
  require_file "${REPO_ROOT}/system/development/zsh/modules/${module}.zsh"
done

require_file "${REPO_ROOT}/dotfiles/vscode/settings.json"
require_file "${REPO_ROOT}/dotfiles/vscode/keybindings.json"
require_file "${REPO_ROOT}/dotfiles/vscode/extensions.txt"
require_file "${REPO_ROOT}/docs/adr/0011-upstream-distribution-exception.md"
require_file "${PROFILE_ROOT}/phase.yaml"

if head -n 1 "${REPO_ROOT}/profiles/dell-latitude-e5470/profile.yaml" | grep -q '^```'; then
  fail "profile.yaml is wrapped in a Markdown code fence"
fi
pass "profile.yaml is a plain YAML document"

printf '\nDevelopment static source validation completed successfully.\n'
