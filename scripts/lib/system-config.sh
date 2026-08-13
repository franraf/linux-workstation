#!/usr/bin/env bash

require_system_config_commands() {
  require_commands install
}

install_system_directory() {
  local directory="$1"
  local mode="${2:-0755}"

  install --directory --owner root --group root --mode "$mode" "$directory"
}

install_system_file() {
  local source="$1"
  local destination="$2"
  local mode="${3:-0644}"

  [[ -f "$source" ]] || die "Canonical system configuration is missing: $source"
  install_system_directory "$(dirname "$destination")"
  install --owner root --group root --mode "$mode" "$source" "$destination"
}

validate_system_file_matches() {
  local source="$1"
  local destination="$2"

  [[ -f "$destination" ]] || die "System configuration was not installed: $destination"
  cmp -s "$source" "$destination" || die "Installed configuration differs from canonical source: $destination"
}
