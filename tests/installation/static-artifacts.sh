#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
readonly PROFILE_DIR="${REPO_ROOT}/profiles/dell-latitude-e5470/01-installation"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

required_files=(
  "packages/installation/base-system-intel.txt"
  "scripts/lib/installation.sh"
  "scripts/lib/storage.sh"
  "system/storage/btrfs-layout.tsv"
  "system/localization/locale.conf.template"
  "system/localization/vconsole.conf.template"
  "system/network/hosts.template"
  "system/sudoers/10-wheel"
  "system/mkinitcpio/10-linux-workstation-intel.conf"
  "system/systemd-boot/loader.conf.template"
  "system/systemd-boot/entry.conf.template"
  "tests/repository/phase-consistency.sh"
)

for relative_path in "${required_files[@]}"; do
  [[ -s "${REPO_ROOT}/${relative_path}" ]] || fail "missing shared artifact: ${relative_path}"
done
pass "shared installation artifacts"

for step in {03..17}; do
  script="$(find "$PROFILE_DIR" -mindepth 2 -maxdepth 2 -type f -path "*/${step}-*/run.sh" -print -quit)"
  [[ -n "$script" ]] || fail "missing run.sh for installation step ${step}"
  bash -n "$script" || fail "bash syntax error: ${script#${REPO_ROOT}/}"
done

for library in logging requirements packages installation storage; do
  bash -n "${REPO_ROOT}/scripts/lib/${library}.sh" || fail "bash syntax error in library: ${library}.sh"
done
bash -n "${REPO_ROOT}/tests/repository/phase-consistency.sh" || fail "bash syntax error in cross-phase consistency test"
pass "shell syntax"

bash "${REPO_ROOT}/tests/repository/phase-consistency.sh"

[[ ! -e "${PROFILE_DIR}/09-install-base-system/packages.txt" ]] || fail "profile-local package list returned"
pass "package list ownership"

layout_file="${REPO_ROOT}/system/storage/btrfs-layout.tsv"
declare -a expected_layout=(
  $'@\t/'
  $'@home\t/home'
  $'@var\t/var'
  $'@var_log\t/var/log'
  $'@var_cache\t/var/cache'
  $'@pkg\t/var/cache/pacman/pkg'
  $'@docker\t/var/lib/docker'
  $'@snapshots\t/.snapshots'
)

mapfile -t actual_layout < <(awk '!/^[[:space:]]*#/ && NF { print $1 "\t" $2 }' "$layout_file")
[[ "${#actual_layout[@]}" -eq "${#expected_layout[@]}" ]] || fail "unexpected Btrfs layout entry count"
for index in "${!expected_layout[@]}"; do
  [[ "${actual_layout[$index]}" == "${expected_layout[$index]}" ]] || fail "Btrfs layout differs at entry $index"
done
pass "canonical Btrfs layout"

mkinitcpio_source="${REPO_ROOT}/system/mkinitcpio/10-linux-workstation-intel.conf"
bash -n "$mkinitcpio_source" || fail "canonical mkinitcpio source is invalid"
# shellcheck disable=SC1090
source "$mkinitcpio_source"
[[ " ${MODULES[*]} " == *" i915 "* ]] || fail "i915 missing from canonical mkinitcpio modules"
[[ " ${HOOKS[*]} " == *" sd-encrypt "* ]] || fail "sd-encrypt missing from canonical mkinitcpio hooks"
[[ " ${HOOKS[*]} " == *" systemd "* ]] || fail "systemd missing from canonical mkinitcpio hooks"
pass "canonical mkinitcpio configuration"

entry_template="${REPO_ROOT}/system/systemd-boot/entry.conf.template"
for placeholder in '@TITLE@' '@INITRAMFS@' '@LUKS_UUID@' '@ROOT_UUID@'; do
  grep -Fq "$placeholder" "$entry_template" || fail "boot entry template missing placeholder: $placeholder"
done
grep -Fq 'rootflags=subvol=@' "$entry_template" || fail "boot entry template missing Btrfs root subvolume"
grep -Fq '=cryptroot' "$entry_template" || fail "boot entry template missing cryptroot mapping"
pass "systemd-boot templates"

[[ "$(cat "${REPO_ROOT}/system/sudoers/10-wheel")" == '%wheel ALL=(ALL:ALL) ALL' ]] || fail "unexpected canonical wheel sudo policy"
pass "sudo policy"

printf '\nStatic installation source validation passed.\n'
