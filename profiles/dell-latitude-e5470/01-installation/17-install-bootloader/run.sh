#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_ESP_PATH="/boot"
readonly DEFAULT_ENTRY_ID="arch-linux"
readonly DEFAULT_ENTRY_TITLE="Arch Linux"
readonly DEFAULT_LOADER_TIMEOUT="3"
readonly EFI_PARTITION_TYPE="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
readonly LOADER_TEMPLATE="${REPO_ROOT}/system/systemd-boot/loader.conf.template"
readonly ENTRY_TEMPLATE="${REPO_ROOT}/system/systemd-boot/entry.conf.template"
readonly KERNEL_IMAGE="/vmlinuz-linux"
readonly MICROCODE_IMAGE="/intel-ucode.img"
readonly INITRAMFS_IMAGE="/initramfs-linux.img"
readonly FALLBACK_INITRAMFS_IMAGE="/initramfs-linux-fallback.img"

ESP_PATH="$DEFAULT_ESP_PATH"
ENTRY_ID="$DEFAULT_ENTRY_ID"
ENTRY_TITLE="$DEFAULT_ENTRY_TITLE"
LOADER_TIMEOUT="$DEFAULT_LOADER_TIMEOUT"
LUKS_DEVICE=""
LUKS_UUID=""
ROOT_DEVICE=""
ROOT_UUID=""
LOADER_CONFIG=""
DEFAULT_ENTRY_FILE=""
FALLBACK_ENTRY_FILE=""

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [options]

Options:
  --esp-path <path>  Default: ${DEFAULT_ESP_PATH}
  --entry-id <id>    Default: ${DEFAULT_ENTRY_ID}
  --title <title>    Default: ${DEFAULT_ENTRY_TITLE}
  --timeout <sec>    Default: ${DEFAULT_LOADER_TIMEOUT}
  --help, -h

Templates:
  ${LOADER_TEMPLATE}
  ${ENTRY_TEMPLATE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --esp-path)
        (($# >= 2)) || die "Missing value for --esp-path."
        ESP_PATH="$2"
        shift 2
        ;;
      --entry-id)
        (($# >= 2)) || die "Missing value for --entry-id."
        ENTRY_ID="$2"
        shift 2
        ;;
      --title)
        (($# >= 2)) || die "Missing value for --title."
        ENTRY_TITLE="$2"
        shift 2
        ;;
      --timeout)
        (($# >= 2)) || die "Missing value for --timeout."
        LOADER_TIMEOUT="$2"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

canonicalize_paths() {
  ESP_PATH="$(canonicalize_existing_path "$ESP_PATH")"
  LOADER_CONFIG="${ESP_PATH}/loader/loader.conf"
  DEFAULT_ENTRY_FILE="${ESP_PATH}/loader/entries/${ENTRY_ID}.conf"
  FALLBACK_ENTRY_FILE="${ESP_PATH}/loader/entries/${ENTRY_ID}-fallback.conf"
}

validate_arguments() {
  [[ "$ENTRY_ID" =~ ^[a-zA-Z0-9._+-]+$ ]] || die "Entry ID contains unsupported characters."
  [[ -n "$ENTRY_TITLE" && "$ENTRY_TITLE" != *$'\n'* ]] || die "Entry title is invalid."
  [[ "$LOADER_TIMEOUT" =~ ^[0-9]+$ ]] || die "Loader timeout must be a non-negative integer."
  ((LOADER_TIMEOUT <= 60)) || die "Loader timeout cannot exceed 60 seconds."
  [[ -s "$LOADER_TEMPLATE" && -s "$ENTRY_TEMPLATE" ]] || die "systemd-boot templates are missing."
}

validate_execution_context() {
  require_installed_arch_context
  require_uefi
  [[ -d /sys/firmware/efi/efivars ]] || die "UEFI variables are unavailable inside the chroot."
}

validate_required_packages() {
  local package
  for package in linux intel-ucode systemd efibootmgr cryptsetup btrfs-progs; do
    pacman -Q "$package" >/dev/null 2>&1 || die "Required package is not installed: $package"
  done
}

validate_esp() {
  require_target_root_mount "$ESP_PATH"
  require_filesystem_type "$ESP_PATH" vfat

  local source
  local partition_type
  source="$(findmnt --noheadings --output SOURCE --target "$ESP_PATH" | xargs)"
  partition_type="$(lsblk --noheadings --nodeps --output PARTTYPE "$source" | xargs | tr '[:lower:]' '[:upper:]')"
  [[ "$partition_type" == "$EFI_PARTITION_TYPE" ]] || die "Mounted partition is not marked as an EFI System Partition."
}

validate_boot_files() {
  local path
  for path in \
    "${ESP_PATH}${KERNEL_IMAGE}" \
    "${ESP_PATH}${MICROCODE_IMAGE}" \
    "${ESP_PATH}${INITRAMFS_IMAGE}" \
    "${ESP_PATH}${FALLBACK_INITRAMFS_IMAGE}"; do
    [[ -s "$path" ]] || die "Required boot file is missing or empty: $path"
  done
}

discover_root_devices() {
  local root_source
  local mapper_name
  root_source="$(findmnt --noheadings --output SOURCE --target / | sed 's/\[.*\]$//' | xargs)"
  [[ -b "$root_source" ]] || die "Unable to identify the root block device."
  mapper_name="$(basename "$root_source")"
  [[ "$mapper_name" == "cryptroot" ]] || die "Expected root mapper name cryptroot, found: $mapper_name"
  cryptsetup status "$mapper_name" >/dev/null 2>&1 || die "Root filesystem is not backed by an active cryptsetup mapping."
  ROOT_DEVICE="$root_source"
  LUKS_DEVICE="$(cryptsetup status "$mapper_name" | awk '$1 == "device:" { print $2; exit }')"
  LUKS_DEVICE="$(readlink -f "$LUKS_DEVICE")"
  [[ -b "$LUKS_DEVICE" ]] || die "LUKS backing device is not a block device: $LUKS_DEVICE"
}

discover_uuids() {
  LUKS_UUID="$(cryptsetup luksUUID "$LUKS_DEVICE")"
  ROOT_UUID="$(blkid --match-tag UUID --output value "$ROOT_DEVICE")"
  [[ "$LUKS_UUID" =~ ^[0-9a-fA-F-]{36}$ ]] || die "Unexpected LUKS UUID format."
  [[ "$ROOT_UUID" =~ ^[0-9a-fA-F-]{36}$ ]] || die "Unexpected root filesystem UUID format."
}

validate_root_filesystem() {
  [[ "$(findmnt --noheadings --output FSTYPE --target / | xargs)" == "btrfs" ]] || die "Expected Btrfs root filesystem."
  [[ "$(findmnt --noheadings --output FSROOT --target / | xargs)" == "/@" ]] || die "Expected @ as the root Btrfs subvolume."
}

show_plan() {
  printf '\nBootloader configuration\n'
  printf '%s\n\n' '------------------------'
  printf 'Implementation:\n  systemd-boot\n\n'
  printf 'ESP:\n  %s\n\n' "$ESP_PATH"
  printf 'Default entry:\n  %s.conf\n\n' "$ENTRY_ID"
  printf 'Fallback entry:\n  %s-fallback.conf\n\n' "$ENTRY_ID"
  printf 'LUKS UUID:\n  %s\n\n' "$LUKS_UUID"
  printf 'Root UUID:\n  %s\n' "$ROOT_UUID"
}

confirm_installation() {
  local confirmation
  printf '\nType BOOTLOADER to install and configure systemd-boot: '
  read -r confirmation
  [[ "$confirmation" == "BOOTLOADER" ]] || die "Bootloader installation was not authorized."
}

render_template() {
  local source_file="$1"
  local output_file="$2"
  shift 2
  local temporary_file
  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN
  cp "$source_file" "$temporary_file"

  local placeholder
  local value
  while (($# >= 2)); do
    placeholder="$1"
    value="$2"
    sed -i "s|${placeholder}|${value}|g" "$temporary_file"
    shift 2
  done

  install --owner root --group root --mode 0644 "$temporary_file" "$output_file"
  rm -f "$temporary_file"
  trap - RETURN
}

install_systemd_boot() {
  log_info "Installing systemd-boot on $ESP_PATH."
  bootctl --esp-path="$ESP_PATH" install
}

write_configuration() {
  install --directory --owner root --group root --mode 0755 "${ESP_PATH}/loader" "${ESP_PATH}/loader/entries"

  render_template "$LOADER_TEMPLATE" "$LOADER_CONFIG" \
    '@ENTRY_ID@' "$ENTRY_ID" \
    '@TIMEOUT@' "$LOADER_TIMEOUT"

  render_template "$ENTRY_TEMPLATE" "$DEFAULT_ENTRY_FILE" \
    '@TITLE@' "$ENTRY_TITLE" \
    '@INITRAMFS@' "$INITRAMFS_IMAGE" \
    '@LUKS_UUID@' "$LUKS_UUID" \
    '@ROOT_UUID@' "$ROOT_UUID"

  render_template "$ENTRY_TEMPLATE" "$FALLBACK_ENTRY_FILE" \
    '@TITLE@' "${ENTRY_TITLE} (fallback initramfs)" \
    '@INITRAMFS@' "$FALLBACK_INITRAMFS_IMAGE" \
    '@LUKS_UUID@' "$LUKS_UUID" \
    '@ROOT_UUID@' "$ROOT_UUID"
}

validate_systemd_boot_installation() {
  bootctl --esp-path="$ESP_PATH" is-installed >/dev/null || die "systemd-boot was not installed successfully."
  [[ -s "${ESP_PATH}/EFI/systemd/systemd-bootx64.efi" ]] || die "Primary systemd-boot EFI binary is missing."
  [[ -s "${ESP_PATH}/EFI/BOOT/BOOTX64.EFI" ]] || die "Fallback EFI boot binary is missing."
}

validate_loader_configuration() {
  grep -Fxq "default ${ENTRY_ID}.conf" "$LOADER_CONFIG" || die "Default loader entry is incorrect."
  grep -Fxq "timeout ${LOADER_TIMEOUT}" "$LOADER_CONFIG" || die "Loader timeout is incorrect."
  grep -Fxq 'console-mode keep' "$LOADER_CONFIG" || die "Loader console mode is missing."
  grep -Fxq 'editor no' "$LOADER_CONFIG" || die "Boot entry editing was not disabled."
}

validate_entry_file() {
  local entry_file="$1"
  local expected_initramfs="$2"
  [[ -s "$entry_file" ]] || die "Boot entry is missing or empty: $entry_file"
  grep -Eq '^title[[:space:]]+.+' "$entry_file" || die "Boot entry title is missing: $entry_file"
  grep -Eq "^[[:space:]]*linux[[:space:]]+${KERNEL_IMAGE}$" "$entry_file" || die "Kernel path is incorrect in: $entry_file"
  grep -Eq "^[[:space:]]*initrd[[:space:]]+${MICROCODE_IMAGE}$" "$entry_file" || die "Microcode image is missing from: $entry_file"
  grep -Eq "^[[:space:]]*initrd[[:space:]]+${expected_initramfs}$" "$entry_file" || die "Initramfs path is incorrect in: $entry_file"
  grep -Fq "rd.luks.name=${LUKS_UUID}=cryptroot" "$entry_file" || die "LUKS mapping parameter is missing from: $entry_file"
  grep -Fq "rd.luks.options=${LUKS_UUID}=discard" "$entry_file" || die "LUKS discard option is missing from: $entry_file"
  grep -Fq "root=UUID=${ROOT_UUID}" "$entry_file" || die "Root filesystem UUID is missing from: $entry_file"
  grep -Fq 'rootfstype=btrfs' "$entry_file" || die "Root filesystem type is missing from: $entry_file"
  grep -Fq 'rootflags=subvol=@' "$entry_file" || die "Root subvolume parameter is missing from: $entry_file"
  grep -Eq '(^|[[:space:]])rw($|[[:space:]])' "$entry_file" || die "Writable root parameter is missing from: $entry_file"
}

validate_boot_entries() {
  bootctl --esp-path="$ESP_PATH" list >/dev/null || die "bootctl could not parse the configured boot entries."
  validate_entry_file "$DEFAULT_ENTRY_FILE" "$INITRAMFS_IMAGE"
  validate_entry_file "$FALLBACK_ENTRY_FILE" "$FALLBACK_INITRAMFS_IMAGE"
}

show_result() {
  printf '\nsystemd-boot installed and configured successfully.\n\n'
  bootctl --esp-path="$ESP_PATH" status --no-pager || true
  printf '\nLoader configuration:\n\n'
  sed 's/^/  /' "$LOADER_CONFIG"
  printf '\nDefault boot entry:\n\n'
  sed 's/^/  /' "$DEFAULT_ENTRY_FILE"
  printf '\nFallback boot entry:\n\n'
  sed 's/^/  /' "$FALLBACK_ENTRY_FILE"
  printf '\nNext step:\n  18-first-boot\n'
}

main() {
  require_root
  require_commands awk basename blkid bootctl cp cryptsetup findmnt grep install lsblk mktemp pacman readlink sed tr xargs
  parse_arguments "$@"
  canonicalize_paths
  validate_arguments
  validate_execution_context
  validate_required_packages
  validate_esp
  validate_boot_files
  discover_root_devices
  discover_uuids
  validate_root_filesystem
  show_plan
  confirm_installation
  install_systemd_boot
  write_configuration
  validate_systemd_boot_installation
  validate_loader_configuration
  validate_boot_entries
  show_result
}

main "$@"
