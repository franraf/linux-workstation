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
      SHELL_FILES+=("$file")
      continue
    fi

    IFS= read -r first_line <"${REPO_ROOT}/${file}" || true
    [[ "$first_line" == '#!/usr/bin/env bash' || "$first_line" == '#!/bin/bash' ]] && SHELL_FILES+=("$file")
  done < <(git -C "$REPO_ROOT" ls-files)
}

main() {
  command -v shellcheck >/dev/null 2>&1 || {
    printf '[FAIL] shellcheck is not installed.\n' >&2
    exit 1
  }
  command -v shfmt >/dev/null 2>&1 || {
    printf '[FAIL] shfmt is not installed.\n' >&2
    exit 1
  }

  collect_shell_files

  ((${#SHELL_FILES[@]} > 0)) || {
    printf '[FAIL] No tracked Bash files were found.\n' >&2
    exit 1
  }

  printf 'Shell quality audit\n-------------------\n\n'
  printf 'Tracked Bash files: %d\n\n' "${#SHELL_FILES[@]}"

  printf '== ShellCheck ==\n\n'
  if shellcheck --severity=warning "${SHELL_FILES[@]/#/${REPO_ROOT}/}"; then
    printf '\n[PASS] ShellCheck reported no warning-or-higher findings.\n'
  else
    printf '\n[FAIL] ShellCheck findings detected.\n' >&2
    SHELLCHECK_STATUS=1
  fi

  printf '\n== shfmt ==\n\n'
  if shfmt -d -ln bash -i 2 -ci "${SHELL_FILES[@]/#/${REPO_ROOT}/}"; then
    printf '\n[PASS] All tracked Bash files match the canonical shfmt style.\n'
  else
    printf '\n[FAIL] shfmt formatting differences detected.\n' >&2
    SHFMT_STATUS=1
  fi

  printf '\nCanonical shell style:\n'
  printf '  language: bash\n'
  printf '  indent:   2 spaces\n'
  printf '  switch:   case labels indented\n'

  if [[ ${SHELLCHECK_STATUS:-0} -ne 0 || ${SHFMT_STATUS:-0} -ne 0 ]]; then
    printf '\nShell quality audit found issues. No files were modified.\n' >&2
    exit 1
  fi

  printf '\nShell quality audit passed.\n'
}

main "$@"
