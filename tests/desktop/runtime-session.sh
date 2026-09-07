#!/usr/bin/env bash

set -Eeuo pipefail

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
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

command -v hyprshot >/dev/null 2>&1 || fail "hyprshot not found"
command -v grim >/dev/null 2>&1 || fail "grim not found"
command -v slurp >/dev/null 2>&1 || fail "slurp not found"
command -v wl-copy >/dev/null 2>&1 || fail "wl-copy not found"
command -v wl-paste >/dev/null 2>&1 || fail "wl-paste not found"
pass "screenshot and clipboard commands"

[[ -d "${HOME}/Pictures/Screenshots" ]] || fail "screenshot directory not found: ${HOME}/Pictures/Screenshots"
pass "screenshot directory"

bindings="$(hyprctl binds)"
grep -qi 'PRINT' <<<"$bindings" || fail "Print Screen binding not found"

keybindings_file="${HOME}/.config/hypr/modules/70-keybindings.lua"
[[ -s "$keybindings_file" ]] || fail "installed Hyprland keybindings module not found"
grep -Fq 'hl.bind("SHIFT + PRINT",' "$keybindings_file" || fail "SHIFT+PRINT binding not found in installed configuration"
grep -Fq 'slurp -d -a 1:1' "$keybindings_file" || fail "1:1 screenshot selector not found in installed configuration"
pass "Print Screen bindings"

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
printf '  - PRINT selects a free region, saves it under ~/Pictures/Screenshots and copies it to the Wayland clipboard\n'
printf '  - SHIFT+PRINT selects a square 1:1 region, saves it under ~/Pictures/Screenshots and copies it to the Wayland clipboard\n'
printf '  - SUPER+Q closes the active window\n'
printf '  - SUPER+arrows move focus between windows\n'
printf '  - SUPER+L locks and authenticates correctly\n'
printf '  - Rofi opens without duplicate binding errors\n'
printf '  - SwayNC receives a notify-send notification and keeps history\n'
printf '  - Kitty clipboard and Unicode rendering work\n'
printf '  - Thunar trash, thumbnails and removable media work\n'
printf '  - suspend/resume and display DPMS behave as configured\n'
