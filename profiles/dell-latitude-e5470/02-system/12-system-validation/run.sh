#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly STATIC_TEST="${REPO_ROOT}/tests/system/static-artifacts.sh"
readonly RUNTIME_TEST="${REPO_ROOT}/tests/system/runtime-state.sh"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Runs the static source gate and the runtime system-state gate for the
completed 02-system phase. This script does not modify system state.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help | -h)
        usage
        exit 0
        ;;
      *)
        printf '[ERROR] Unknown argument: %s\n' "$1" >&2
        exit 1
        ;;
    esac
  done
}

main() {
  parse_arguments "$@"

  [[ -f "$STATIC_TEST" ]] || {
    printf '[ERROR] Missing static validation: %s\n' "$STATIC_TEST" >&2
    exit 1
  }
  [[ -f "$RUNTIME_TEST" ]] || {
    printf '[ERROR] Missing runtime validation: %s\n' "$RUNTIME_TEST" >&2
    exit 1
  }

  printf '\n== Static source validation ==\n\n'
  bash "$STATIC_TEST"

  printf '\n== Runtime system validation ==\n\n'
  bash "$RUNTIME_TEST"

  printf '\n02-system validation completed successfully.\n'
  printf '\nNext phase:\n  03-desktop\n'
}

main "$@"
