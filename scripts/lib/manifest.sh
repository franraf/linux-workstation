#!/usr/bin/env bash

# Minimal readers for the YAML subset used by profile.yaml and phase.yaml.
# These helpers intentionally avoid external YAML runtimes so they remain
# usable before the Development phase.

manifest_profile_phases() {
  local profile_file="$1"

  awk '
    /^automation:[[:space:]]*$/ { in_automation=1; next }
    in_automation && /^[^[:space:]]/ { in_automation=0; in_phases=0 }
    in_automation && /^  phases:[[:space:]]*$/ { in_phases=1; next }
    in_phases && /^  [^[:space:]-]/ { in_phases=0 }
    in_phases && /^    -[[:space:]]+/ {
      value=$0
      sub(/^    -[[:space:]]+/, "", value)
      gsub(/["\047]/, "", value)
      print value
    }
  ' "$profile_file"
}

manifest_phase_field() {
  local phase_file="$1"
  local field="$2"

  awk -v wanted_field="$field" '
    /^phase:[[:space:]]*$/ { in_phase=1; next }
    in_phase && /^[^[:space:]]/ { in_phase=0 }
    in_phase && $0 ~ "^  " wanted_field ":[[:space:]]*" {
      value=$0
      sub("^  " wanted_field ":[[:space:]]*", "", value)
      gsub(/^["\047]|["\047]$/, "", value)
      print value
      exit
    }
  ' "$phase_file"
}

manifest_phase_steps() {
  local phase_file="$1"

  awk '
    /^execution:[[:space:]]*$/ { in_execution=1; next }
    in_execution && /^[^[:space:]]/ { in_execution=0; in_order=0 }
    in_execution && /^  order:[[:space:]]*$/ { in_order=1; next }
    in_order && /^  [^[:space:]-]/ { in_order=0 }
    in_order && /^    -[[:space:]]+/ {
      value=$0
      sub(/^    -[[:space:]]+/, "", value)
      gsub(/["\047]/, "", value)
      print value
    }
  ' "$phase_file"
}

manifest_step_field() {
  local phase_file="$1"
  local step="$2"
  local field="$3"

  awk -v wanted_step="$step" -v wanted_field="$field" '
    /^steps:[[:space:]]*$/ { in_steps=1; next }
    in_steps && /^[^[:space:]]/ { in_steps=0; in_step=0 }
    in_steps && /^  [^[:space:]][^:]*:[[:space:]]*$/ {
      key=$0
      sub(/^  /, "", key)
      sub(/:[[:space:]]*$/, "", key)
      in_step=(key == wanted_step)
      next
    }
    in_step && $0 ~ "^    " wanted_field ":[[:space:]]*" {
      value=$0
      sub("^    " wanted_field ":[[:space:]]*", "", value)
      gsub(/^["\047]|["\047]$/, "", value)
      print value
      exit
    }
  ' "$phase_file"
}
