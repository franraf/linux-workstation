#!/usr/bin/env bash

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

setup_error_trap() {
  local script_name="$1"
  trap 'rc=$?; printf "[ERROR] %s failed at line %s with exit code %s.\n" '"'"$script_name"'"' "$LINENO" "$rc" >&2; exit "$rc"' ERR
}
