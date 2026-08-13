#!/usr/bin/env bash

set -Eeuo pipefail

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

command -v hyprctl >/dev/null 2>&1 || fail "hyprctl not found"
[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || fail "not running inside a Hyprland session"

errors="$(hyprctl configerrors 2>&1)" || fail "hyprctl configerrors failed"
if [[ -n "$errors" && "$errors" != "ok" ]]; then
  printf '%s\n' "$errors" >&2
  fail "Hyprland reports configuration errors"
fi
pass "Hyprland configuration errors"

hyprctl monitors >/dev/null 2>&1 || fail "could not query monitors"
hyprctl devices >/dev/null 2>&1 || fail "could not query input devices"
hyprctl binds >/dev/null 2>&1 || fail "could not query bindings"
pass "Hyprland runtime queries"

for process in waybar hypridle swaync; do
  pids="$(pgrep -x "$process" || true)"
  if [[ -z "$pids" ]]; then
    count=0
  else
    count="$(printf '%s\n' "$pids" | wc -l)"
  fi
  [[ "$count" -eq 1 ]] || fail "expected exactly one ${process} process, found ${count}"
done
pass "session autostart processes"

systemctl is-enabled greetd.service >/dev/null 2>&1 || fail "greetd.service is not enabled"
pass "greetd enabled"

printf '\nManual checks still required:\n'
printf '  - SUPER+Q closes the active window\n'
printf '  - SUPER+arrows move focus between windows\n'
printf '  - SUPER+L locks and authenticates correctly\n'
printf '  - Rofi opens without duplicate binding errors\n'
printf '  - SwayNC receives a notify-send notification and keeps history\n'
printf '  - Kitty clipboard and Unicode rendering work\n'
printf '  - Thunar trash, thumbnails and removable media work\n'
printf '  - suspend/resume and display DPMS behave as configured\n'
