#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly REPO_ROOT

declare -a SHELL_FILES=()

collect_shell_files() {
  local file first_line
  while IFS= read -r file; do
    [[ -f "${REPO_ROOT}/${file}" ]] || continue
    if [[ "$file" == *.sh ]]; then
      SHELL_FILES+=("${REPO_ROOT}/${file}")
      continue
    fi
    IFS= read -r first_line <"${REPO_ROOT}/${file}" || true
    [[ "$first_line" == '#!/usr/bin/env bash' || "$first_line" == '#!/bin/bash' ]] && SHELL_FILES+=("${REPO_ROOT}/${file}")
  done < <(git -C "$REPO_ROOT" ls-files)
}

replace_exact_patterns() {
  local file
  for file in "${SHELL_FILES[@]}"; do
    perl -0pi -e 's/^readonly SCRIPT_NAME="\$\(basename "\$0"\)"$/SCRIPT_NAME="\$\(basename "\$0"\)"\nreadonly SCRIPT_NAME/mg' "$file"
    perl -0pi -e 's/^readonly SCRIPT_DIRECTORY="\$\(cd -- "\$\(dirname -- "\$\{BASH_SOURCE\[0\]\}"\)" && pwd\)"$/SCRIPT_DIRECTORY="\$\(cd -- "\$\(dirname -- "\$\{BASH_SOURCE[0]\}"\)" && pwd\)"\nreadonly SCRIPT_DIRECTORY/mg' "$file"
    perl -0pi -e 's/^readonly REPO_ROOT="\$\(cd -- "\$\{SCRIPT_DIRECTORY\}\/\.\.\/\.\.\/\.\.\/\.\." && pwd\)"$/REPO_ROOT="\$\(cd -- "\$\{SCRIPT_DIRECTORY\}\/\.\.\/\.\.\/\.\.\/\.\." && pwd\)"\nreadonly REPO_ROOT/mg' "$file"
    perl -0pi -e 's/^readonly REPO_ROOT="\$\(cd -- "\$\{SCRIPT_DIRECTORY\}\/\.\.\/\.\." && pwd\)"$/REPO_ROOT="\$\(cd -- "\$\{SCRIPT_DIRECTORY\}\/\.\.\/\.\." && pwd\)"\nreadonly REPO_ROOT/mg' "$file"
    perl -0pi -e 's/^readonly REPO_ROOT="\$\(cd -- "\$\{SCRIPT_DIRECTORY\}\/\.\." && pwd\)"$/REPO_ROOT="\$\(cd -- "\$\{SCRIPT_DIRECTORY\}\/\.\." && pwd\)"\nreadonly REPO_ROOT/mg' "$file"
    perl -0pi -e 's/^  local holder_directory="\/sys\/class\/block\/\$\(basename "\$TARGET_PARTITION"\)\/holders"$/  local holder_directory\n  holder_directory="\/sys\/class\/block\/\$\(basename "\$TARGET_PARTITION"\)\/holders"/mg' "$file"
    perl -0pi -e 's/^  local saved_phase_file="\$\(phase_file_for "\$saved_phase"\)"$/  local saved_phase_file\n  saved_phase_file="\$\(phase_file_for "\$saved_phase"\)"/mg' "$file"
  done
}

fix_known_findings() {
  sed -i 's/LANG="$PRIMARY_LOCALE" LC_ALL= locale charmap/LANG="$PRIMARY_LOCALE" LC_ALL='"'"''"'"' locale charmap/' \
    "${REPO_ROOT}/profiles/dell-latitude-e5470/01-installation/13-configure-localization/run.sh"

  sed -i '/^[[:space:]]*show_plan_without_identity=false$/d' \
    "${REPO_ROOT}/profiles/dell-latitude-e5470/04-development/01-version-control/run.sh"

  sed -i 's/read -r subvolume mountpoint options/read -r subvolume mountpoint _options/' \
    "${REPO_ROOT}/tests/system/runtime-state.sh"

  sed -i 's/pass "~\/.zshenv matches canonical source"/pass "${HOME}\/\.zshenv matches canonical source"/' \
    "${REPO_ROOT}/tests/development/runtime-state.sh"
  sed -i 's/fail "~\/.zshenv differs from canonical source"/fail "${HOME}\/\.zshenv differs from canonical source"/' \
    "${REPO_ROOT}/tests/development/runtime-state.sh"

  local initramfs_file="${REPO_ROOT}/profiles/dell-latitude-e5470/01-installation/16-configure-initramfs/run.sh"
  if ! grep -Fq '# shellcheck disable=SC1090' "$initramfs_file"; then
    sed -i '/^source "$SOURCE_CONFIG"$/i # SOURCE_CONFIG is a canonical repository path resolved at runtime.\n# shellcheck disable=SC1090' "$initramfs_file"
  fi

  local logging_file="${REPO_ROOT}/scripts/lib/logging.sh"
  if ! grep -Fq '# shellcheck disable=SC2154,SC2027' "$logging_file"; then
    sed -i '/^[[:space:]]*trap .* ERR$/i\  # The ERR trap intentionally expands rc and LINENO when the trap executes.\n  # shellcheck disable=SC2154,SC2027' "$logging_file"
  fi
}

main() {
  command -v perl >/dev/null 2>&1 || { printf '[FAIL] perl is required.\n' >&2; exit 1; }
  command -v sed >/dev/null 2>&1 || { printf '[FAIL] sed is required.\n' >&2; exit 1; }
  command -v shellcheck >/dev/null 2>&1 || { printf '[FAIL] shellcheck is required.\n' >&2; exit 1; }
  command -v shfmt >/dev/null 2>&1 || { printf '[FAIL] shfmt is required.\n' >&2; exit 1; }

  collect_shell_files
  ((${#SHELL_FILES[@]} > 0)) || { printf '[FAIL] No tracked Bash files found.\n' >&2; exit 1; }

  # Format first so compact one-line functions become predictable before targeted fixes.
  shfmt -w -ln bash -i 2 -ci "${SHELL_FILES[@]}"
  replace_exact_patterns
  fix_known_findings
  shfmt -w -ln bash -i 2 -ci "${SHELL_FILES[@]}"

  printf '\nRunning ShellCheck after migration...\n\n'
  shellcheck --severity=warning "${SHELL_FILES[@]}"

  printf '\nRunning shfmt verification after migration...\n\n'
  shfmt -d -ln bash -i 2 -ci "${SHELL_FILES[@]}"

  printf '\nShell quality migration completed. Review git diff before committing.\n'
}

main "$@"
