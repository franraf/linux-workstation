#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly REPO_ROOT

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  printf '[PASS] %s\n' "$*"
  ((PASS_COUNT += 1))
}
warn() {
  printf '[WARN] %s\n' "$*" >&2
  ((WARN_COUNT += 1))
}
fail() {
  printf '[FAIL] %s\n' "$*" >&2
  ((FAIL_COUNT += 1))
}
section() { printf '\n== %s ==\n\n' "$*"; }

check_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 && pass "Command available: $command_name" || fail "Command missing: $command_name"
}

check_package_file() {
  local file="$1"
  local package
  while IFS= read -r package; do
    package="${package%%#*}"
    package="${package//[[:space:]]/}"
    [[ -n "$package" ]] || continue
    pacman -Q "$package" >/dev/null 2>&1 && pass "Installed package: $package" || fail "Missing package: $package"
  done <"$file"
}

[[ ${EUID:-$(id -u)} -ne 0 ]] || {
  printf '[FAIL] Development runtime validation must run as a normal user.\n' >&2
  exit 1
}

section "Git"
check_command git
git config --global --get user.name >/dev/null 2>&1 && pass "Git user.name is configured" || fail "Git user.name is missing"
git config --global --get user.email >/dev/null 2>&1 && pass "Git user.email is configured" || fail "Git user.email is missing"
[[ "$(git config --global --get init.defaultBranch 2>/dev/null || true)" == "main" ]] && pass "Git default branch is main" || fail "Git default branch is not main"

section "Shell"
check_package_file "${REPO_ROOT}/packages/development/shell.txt"
check_command zsh
check_command starship
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
[[ "$current_shell" == "$(command -v zsh)" ]] && pass "Zsh is the login shell" || fail "Login shell is not Zsh: $current_shell"
cmp -s "${REPO_ROOT}/system/development/zsh/zshenv" "${HOME}/.zshenv" && pass "${HOME}/.zshenv matches canonical source" || fail "${HOME}/.zshenv differs from canonical source"
cmp -s "${REPO_ROOT}/system/development/zsh/zshrc" "${HOME}/.config/zsh/.zshrc" && pass "Zsh entrypoint matches canonical source" || fail "Zsh entrypoint is missing or differs from canonical source"
cmp -s "${REPO_ROOT}/system/development/starship/starship.toml" "${HOME}/.config/starship/starship.toml" && pass "Starship configuration matches canonical source" || fail "Starship configuration is missing or differs from canonical source"
zsh -lic 'true' >/dev/null 2>&1 && pass "Interactive Zsh starts without error" || fail "Interactive Zsh startup failed"

section "Visual Studio Code"
check_package_file "${REPO_ROOT}/packages/development/code-editor-runtime.txt"
check_command code
check_command chezmoi
code_version_output="$(code --version 2>/dev/null || true)"
code_version="${code_version_output%%$'\n'*}"
[[ -n "$code_version" ]] && pass "Visual Studio Code version: $code_version" || fail "Visual Studio Code did not return a version"
cmp -s "${REPO_ROOT}/dotfiles/home/private_dot_config/private_Code/User/settings.json" "${HOME}/.config/Code/User/settings.json" && pass "VS Code settings match canonical chezmoi source" || fail "VS Code settings differ from canonical chezmoi source"
cmp -s "${REPO_ROOT}/dotfiles/home/private_dot_config/private_Code/User/keybindings.json" "${HOME}/.config/Code/User/keybindings.json" && pass "VS Code keybindings match canonical chezmoi source" || fail "VS Code keybindings differ from canonical chezmoi source"
if chezmoi -S "$REPO_ROOT" diff "${HOME}/.config/Code/User/settings.json" "${HOME}/.config/Code/User/keybindings.json" | grep -q .; then
  fail "chezmoi reports unapplied VS Code configuration"
else
  pass "chezmoi reports VS Code configuration converged"
fi
extensions="$(code --list-extensions 2>/dev/null || true)"
grep -Fxiq 'ms-vscode-remote.remote-containers' <<<"$extensions" && pass "Dev Containers extension is installed" || fail "Dev Containers extension is missing"

section "Containers"
check_package_file "${REPO_ROOT}/packages/development/container-platform.txt"
systemctl is-active --quiet docker.service && pass "docker.service is active" || fail "docker.service is not active"
user_groups="$(id -nG)"
[[ " $user_groups " == *" docker "* ]] && pass "Current session includes docker group" || fail "Current session does not include docker group; log out and in after configuration"
docker info >/dev/null 2>&1 && pass "Docker is accessible without sudo" || fail "Docker is not accessible without sudo"
docker compose version >/dev/null 2>&1 && pass "Docker Compose is available" || fail "Docker Compose is unavailable"
docker buildx version >/dev/null 2>&1 && pass "Docker Buildx is available" || fail "Docker Buildx is unavailable"

section "CLI tools"
check_package_file "${REPO_ROOT}/packages/development/cli-tools.txt"
for command_name in bat delta eza fd fzf http jq just lazygit make rg shellcheck shfmt tmux yq; do
  check_command "$command_name"
done

section "AI tooling"
check_package_file "${REPO_ROOT}/packages/development/ai-tooling.txt"
check_command codex
codex_version="$(codex --version 2>/dev/null || true)"
[[ -n "$codex_version" ]] && pass "Codex CLI version: $codex_version" || fail "Codex CLI did not return a version"

section "Host runtime policy"
for excluded_command in dotnet node terraform kubectl helm aws; do
  if command -v "$excluded_command" >/dev/null 2>&1; then
    warn "Excluded project runtime/tool is present on the host: $excluded_command"
  else
    pass "Excluded project runtime/tool absent: $excluded_command"
  fi
done

printf '\n========================================\nDevelopment validation summary\n========================================\n\n'
printf 'Passed:   %d\nWarnings: %d\nFailed:   %d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"

((FAIL_COUNT == 0)) || exit 1

printf '\nAutomated development validation completed successfully.\n'
printf '\nManual validation checklist for a new or rebuilt workstation:\n'
printf '  - confirm GitHub SSH authentication and push/pull using a controlled repository\n'
printf '  - open Visual Studio Code graphically and verify the integrated Zsh terminal\n'
printf '  - open a real project in a Dev Container and run its tests\n'
printf '  - run `codex login` if needed and validate one reviewed task in a controlled repository\n'
printf '\nThe validated baseline for this profile is recorded in its phase manifest.\n'
