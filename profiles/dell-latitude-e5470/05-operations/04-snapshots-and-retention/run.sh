#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../../.." && pwd)"

source "${REPO_ROOT}/scripts/lib/logging.sh"

PACKAGE_FILE="${REPO_ROOT}/packages/operations/snapshots.txt"
SNAPPER_CONFIG="root"
SNAPSHOT_DIR="/.snapshots"
CONFIG_FILE="/etc/snapper/configs/${SNAPPER_CONFIG}"
CONFIG_TEMPLATE="/usr/share/snapper/config-templates/default"
EXPECTED_SNAPSHOT_SUBVOLUME="@snapshots"

trap 'log_error "run.sh failed at line ${LINENO} with exit code $?"' ERR

if [[ ${EUID} -ne 0 ]]; then
  log_error "This step must be run as root."
  exit 1
fi

if [[ ! -r "${PACKAGE_FILE}" ]]; then
  log_error "Package declaration not found: ${PACKAGE_FILE}"
  exit 1
fi

if [[ "$(findmnt -n -o FSTYPE /)" != "btrfs" ]]; then
  log_error "Root filesystem is not Btrfs."
  exit 1
fi

printf '\nBtrfs snapshot setup\n'
printf '%s\n' '--------------------'
printf '\nPolicy:\n'
printf '  tool: Snapper\n'
printf '  configuration: %s\n' "${SNAPPER_CONFIG}"
printf '  snapshot location: %s\n' "${SNAPSHOT_DIR}"
printf '  timeline snapshots: disabled\n'
printf '  maintenance retention: 10 pre/post pairs\n'
printf '  manual retention: 5 snapshots\n'
printf '  automatic destructive cleanup: not enabled by this step\n'

if ! pacman -Q snapper >/dev/null 2>&1; then
  printf '\nPackage to install:\n  - snapper\n'
  printf '\nType SNAPSHOTS to install and configure Snapper: '
  read -r confirmation
  if [[ "${confirmation}" != "SNAPSHOTS" ]]; then
    log_error "Snapshot setup cancelled."
    exit 1
  fi
  pacman -S --needed snapper
else
  log_info "Snapper is already installed."
fi

if ! mountpoint -q "${SNAPSHOT_DIR}"; then
  log_error "${SNAPSHOT_DIR} is not a mount point."
  log_error "The canonical Btrfs layout requires ${EXPECTED_SNAPSHOT_SUBVOLUME} to be mounted there."
  exit 1
fi

if [[ "$(findmnt -n -o FSTYPE "${SNAPSHOT_DIR}")" != "btrfs" ]]; then
  log_error "${SNAPSHOT_DIR} is not backed by Btrfs."
  exit 1
fi

snapshot_source="$(findmnt -n -o SOURCE "${SNAPSHOT_DIR}")"
if [[ "${snapshot_source}" != *"[/${EXPECTED_SNAPSHOT_SUBVOLUME}]" ]]; then
  log_error "Unexpected snapshot mount source: ${snapshot_source}"
  log_error "Expected the canonical Btrfs subvolume ${EXPECTED_SNAPSHOT_SUBVOLUME}."
  exit 1
fi

if ! btrfs subvolume show "${SNAPSHOT_DIR}" >/dev/null 2>&1; then
  log_error "${SNAPSHOT_DIR} is not a valid Btrfs subvolume."
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  if [[ ! -r "${CONFIG_TEMPLATE}" ]]; then
    log_error "Snapper configuration template not found: ${CONFIG_TEMPLATE}"
    exit 1
  fi

  log_info "Canonical ${EXPECTED_SNAPSHOT_SUBVOLUME} mount detected; creating Snapper config without recreating ${SNAPSHOT_DIR}."
  install -Dm600 "${CONFIG_TEMPLATE}" "${CONFIG_FILE}"
fi

# Enforce the approved non-destructive baseline on every run.
sed -i \
  -e 's|^SUBVOLUME=.*|SUBVOLUME="/"|' \
  -e 's|^FSTYPE=.*|FSTYPE="btrfs"|' \
  -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' \
  -e 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="no"/' \
  -e 's/^NUMBER_CLEANUP=.*/NUMBER_CLEANUP="no"/' \
  -e 's/^EMPTY_PRE_POST_CLEANUP=.*/EMPTY_PRE_POST_CLEANUP="no"/' \
  "${CONFIG_FILE}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  log_error "Snapper configuration was not created: ${CONFIG_FILE}"
  exit 1
fi

configured_subvolume="$(awk -F= '$1 == "SUBVOLUME" {value=$2; gsub(/^\"|\"$/, "", value); print value; exit}' "${CONFIG_FILE}")"
configured_fstype="$(awk -F= '$1 == "FSTYPE" {value=$2; gsub(/^\"|\"$/, "", value); print value; exit}' "${CONFIG_FILE}")"

if [[ "${configured_subvolume}" != "/" ]]; then
  log_error "Snapper root configuration does not target /. Found: ${configured_subvolume:-<empty>}"
  exit 1
fi

if [[ "${configured_fstype}" != "btrfs" ]]; then
  log_error "Snapper root configuration does not declare Btrfs. Found: ${configured_fstype:-<empty>}"
  exit 1
fi

if ! snapper -c "${SNAPPER_CONFIG}" get-config >/dev/null; then
  log_error "Snapper cannot load configuration '${SNAPPER_CONFIG}'."
  exit 1
fi

log_info "Snapper root configuration exists on the canonical @snapshots mount."
log_info "Timeline and automatic cleanup are disabled until snapshot classification and retention enforcement are validated."

printf '\nCurrent Snapper state:\n\n'
snapper -c "${SNAPPER_CONFIG}" list

printf '\nSnapshot foundation configured successfully.\n'
