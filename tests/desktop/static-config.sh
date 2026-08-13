#!/usr/bin/env bash

set -Eeuo pipefail

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
HYPR="${CONFIG_HOME}/hypr"

[[ -s "${HYPR}/hyprland.lua" ]] || fail "hyprland.lua is missing"
[[ ! -e "${HYPR}/hyprland.conf" ]] || fail "legacy hyprland.conf is still active"

for module in 10-environment 20-monitor 30-input 40-general 50-autostart 60-session-lock 70-keybindings 80-appearance; do
  [[ -s "${HYPR}/modules/${module}.lua" ]] || fail "missing Hyprland module: ${module}.lua"
done
pass "Hyprland Lua configuration tree"

KEYS="${HYPR}/modules/70-keybindings.lua"
for binding in \
  'SUPER + SPACE' \
  'SUPER + N' \
  'SUPER + RETURN' \
  'SUPER + E' \
  'SUPER + Q' \
  'SUPER + F' \
  'SUPER + V' \
  'SUPER + LEFT' \
  'SUPER + RIGHT' \
  'SUPER + UP' \
  'SUPER + DOWN'; do
  grep -Fq "$binding" "$KEYS" || fail "missing keybinding: ${binding}"
done
pass "global keybindings"

AUTOSTART="${HYPR}/modules/50-autostart.lua"
for process in waybar hypridle swaync; do
  [[ "$(grep -c "pidof ${process} || ${process}" "$AUTOSTART")" -eq 1 ]] || fail "${process} must appear exactly once in autostart"
done
pass "autostart registry"

[[ -s "${CONFIG_HOME}/waybar/config.jsonc" ]] || fail "Waybar config missing"
! grep -Eq '"width"[[:space:]]*:' "${CONFIG_HOME}/waybar/config.jsonc" || fail "Waybar must not use a fixed width"
[[ -s "${HYPR}/hyprlock.conf" ]] || fail "Hyprlock config missing"
[[ -s "${HYPR}/hypridle.conf" ]] || fail "Hypridle config missing"
[[ -s "${CONFIG_HOME}/rofi/config.rasi" ]] || fail "Rofi config missing"
[[ -s "${CONFIG_HOME}/swaync/config.json" ]] || fail "SwayNC config missing"
[[ -s "${CONFIG_HOME}/kitty/kitty.conf" ]] || fail "Kitty config missing"
pass "desktop component configuration files"
