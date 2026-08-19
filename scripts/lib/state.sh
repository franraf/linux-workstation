#!/usr/bin/env bash

state_root() {
  printf '%s/linux-workstation\n' "${XDG_STATE_HOME:-${HOME}/.local/state}"
}

state_file_for_profile() {
  local profile="$1"
  printf '%s/%s/execution.state\n' "$(state_root)" "$profile"
}

state_write() {
  local profile="$1"
  local phase="$2"
  local last_completed_step="$3"
  local next_step="$4"
  local status="$5"
  local file
  local directory
  local temporary

  file="$(state_file_for_profile "$profile")"
  directory="$(dirname "$file")"
  mkdir -p "$directory"
  chmod 700 "$directory"
  temporary="${file}.tmp.$$"

  umask 077
  {
    printf 'profile=%s\n' "$profile"
    printf 'phase=%s\n' "$phase"
    printf 'last_completed_step=%s\n' "$last_completed_step"
    printf 'next_step=%s\n' "$next_step"
    printf 'status=%s\n' "$status"
  } >"$temporary"
  mv -f "$temporary" "$file"
}

state_read_field() {
  local file="$1"
  local field="$2"
  local line

  [[ -f "$file" ]] || return 1
  while IFS= read -r line; do
    [[ "$line" == "${field}="* ]] || continue
    printf '%s\n' "${line#*=}"
    return 0
  done <"$file"
  return 1
}

state_clear() {
  local profile="$1"
  local file
  local directory

  file="$(state_file_for_profile "$profile")"
  directory="$(dirname "$file")"
  rm -f "$file"
  rmdir "$directory" 2>/dev/null || true
}
