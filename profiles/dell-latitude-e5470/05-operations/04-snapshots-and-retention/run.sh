#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../../.." && pwd)"

source "${REPO_ROOT}/scripts/lib/logging.sh"

PACKAGE_FILE="${REPO_ROOT}/packages/operations/snapshots.txt"
SNAPPER_CONFIG="root"
SNAPSHOT_DIR="/.snapshots"

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

if [[ ! -f "/etc/snapper/configs/${SNAPPER_CONFIG}" ]]; then
  if [[ -e "${SNAPSHOT_DIR}" ]]; then
    log_error "${SNAPSHOT_DIR} already exists but Snapper config '${SNAPPER_CONFIG}' does not. Refusing to modify the existing Btrfs layout automatically."
    log_error "Inspect the existing @snapshots mount before creating the Snapper configuration."
    exit 1
  fi

  snapper -c "${SNAPPER_CONFIG}" create-config /
fi

CONFIG_FILE="/etc/snapper/configs/${SNAPPER_CONFIG}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  log_error "Snapper configuration was not created: ${CONFIG_FILE}"
  exit 1
fi

# Timeline snapshots are intentionally outside the approved policy.
sed -i 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' "${CONFIG_FILE}"

log_info "Snapper configuration exists and timeline snapshots are disabled."
log_info "Retention enforcement for maintenance pairs and manual snapshots remains explicit until snapshot tagging is integrated with the updater."

printf '\nCurrent Snapper state:\n\n'
snapper -c "${SNAPPER_CONFIG}" list

printf '\nSnapshot foundation configured successfully.\n'
