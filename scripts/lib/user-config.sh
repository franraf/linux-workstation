#!/usr/bin/env bash

# Shared helpers for scripts that install configuration into a normal user's home.
# Requires logging.sh to be sourced first so die() is available.

resolve_normal_user() {
  local username="${1:-}"

  [[ -n "$username" ]] || die "Target user is required."
  [[ "$username" != "root" ]] || die "Configuration must target a normal user, not root."
  id "$username" >/dev/null 2>&1 || die "User does not exist: $username"

  local home group
  home="$(getent passwd "$username" | cut -d: -f6)"
  group="$(id -gn "$username")"

  [[ -n "$home" && -d "$home" ]] || die "Could not resolve a valid home directory for ${username}."
  [[ -n "$group" ]] || die "Could not resolve the primary group for ${username}."

  TARGET_USER="$username"
  TARGET_HOME="$home"
  TARGET_GROUP="$group"

  readonly TARGET_USER TARGET_HOME TARGET_GROUP
}

user_config_path() {
  local relative_path="$1"
  printf '%s/.config/%s\n' "$TARGET_HOME" "$relative_path"
}

install_user_directory() {
  local target="$1"
  local mode="${2:-0755}"

  install -d -m "$mode" -o "$TARGET_USER" -g "$TARGET_GROUP" "$target"
}

install_user_file() {
  local source="$1"
  local target="$2"
  local mode="${3:-0644}"

  [[ -f "$source" ]] || die "Source file does not exist: $source"
  install -m "$mode" -o "$TARGET_USER" -g "$TARGET_GROUP" "$source" "$target"
}

require_user_config_commands() {
  require_commands cut getent id install
}
