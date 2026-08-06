#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly DEFAULT_ESP_PATH="/boot"
readonly DEFAULT_ENTRY_ID="arch-linux"
readonly DEFAULT_ENTRY_TITLE="Arch Linux"
readonly DEFAULT_LOADER_TIMEOUT="3"

readonly LOADER_DIRECTORY="loader"
readonly ENTRY_DIRECTORY="loader/entries"

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

log() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  local line_number=$1

  printf '[ERROR] %s failed at line %s with exit code %s.\n' \
    "$SCRIPT_NAME" \
    "$line_number" \
    "$exit_code" >&2

  exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [options]

Options:
  --esp-path <path>
      Mounted EFI System Partition.
      Default: ${DEFAULT_ESP_PATH}

  --entry-id <id>
      Boot Loader Specification entry identifier.
      Default: ${DEFAULT_ENTRY_ID}

  --title <title>
      Title displayed by systemd-boot.
      Default: ${DEFAULT_ENTRY_TITLE}

  --timeout <seconds>
      Boot menu timeout.
      Default: ${DEFAULT_LOADER_TIMEOUT}

  --help, -h
      Show this help message.

Examples:
  ./$SCRIPT_NAME

  ./$SCRIPT_NAME \\
    --esp-path /boot \\
    --entry-id arch-linux \\
    --title "Arch Linux" \\
    --timeout 3

This script must run inside the installed Arch Linux system through
the chroot transition established by the installation profile.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    blkid
    bootctl
    cryptsetup
    findmnt
    grep
    install
    lsblk
    mktemp
    pacman
    readlink
    sed
    stat
    awk
    cat
    tr
    xargs
  )

  local command_name

  for command_name in "${commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      die "Required command not found: $command_name"
  done
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --esp-path)
        (($# >= 2)) ||
          die "Missing value for --esp-path."

        ESP_PATH="$2"
        shift 2
        ;;

      --entry-id)
        (($# >= 2)) ||
          die "Missing value for --entry-id."

        ENTRY_ID="$2"
        shift 2
        ;;

      --title)
        (($# >= 2)) ||
          die "Missing value for --title."

        ENTRY_TITLE="$2"
        shift 2
        ;;

      --timeout)
        (($# >= 2)) ||
          die "Missing value for --timeout."

        LOADER_TIMEOUT="$2"
        shift 2
        ;;

      --help | -h)
        usage
        exit 0
        ;;

      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

canonicalize_paths() {
  [[ -e "$ESP_PATH" ]] ||
    die "ESP path does not exist: $ESP_PATH"

  ESP_PATH="$(readlink -f "$ESP_PATH")"

  LOADER_CONFIG="${ESP_PATH}/${LOADER_DIRECTORY}/loader.conf"
  DEFAULT_ENTRY_FILE="${ESP_PATH}/${ENTRY_DIRECTORY}/${ENTRY_ID}.conf"
  FALLBACK_ENTRY_FILE="${ESP_PATH}/${ENTRY_DIRECTORY}/${ENTRY_ID}-fallback.conf"
}

validate_arguments() {
  [[ "$ESP_PATH" == /* ]] ||
    die "ESP path must be absolute."

  [[ "$ENTRY_ID" =~ ^[a-zA-Z0-9._+-]+$ ]] ||
    die "Entry ID contains unsupported characters."

  [[ -n "$ENTRY_TITLE" ]] ||
    die "Entry title cannot be empty."

  [[ "$ENTRY_TITLE" != *$'\n'* ]] ||
    die "Entry title cannot contain line breaks."

  [[ "$LOADER_TIMEOUT" =~ ^[0-9]+$ ]] ||
    die "Loader timeout must be a non-negative integer."

  ((LOADER_TIMEOUT <= 60)) ||
    die "Loader timeout cannot exceed 60 seconds."
}

validate_execution_context() {
  [[ -f /etc/os-release ]] ||
    die "The current root does not contain /etc/os-release."

  grep -q '^ID=arch$' /etc/os-release ||
    die "This script must run inside the installed Arch Linux system."

  [[ -s /etc/fstab ]] ||
    die "The installed-system fstab is missing or empty."

  [[ -d /sys/firmware/efi ]] ||
    die "The installation environment was not started in UEFI mode."

  [[ -d /sys/firmware/efi/efivars ]] ||
    die "UEFI variables are unavailable inside the chroot."
}

validate_required_packages() {
  local packages=(
    linux
    intel-ucode
    systemd
    efibootmgr
    cryptsetup
    btrfs-progs
  )

  local package

  for package in "${packages[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 ||
      die "Required package is not installed: $package"
  done
}

validate_esp() {
  local filesystem_type
  local partition_type
  local expected_partition_type

  expected_partition_type="C12A7328-F81F-11D2-BA4B-00A0C93EC93B"

  findmnt --mountpoint "$ESP_PATH" >/dev/null 2>&1 ||
    die "ESP path is not a mountpoint: $ESP_PATH"

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$ESP_PATH" |
      xargs
  )"

  [[ "$filesystem_type" == "vfat" ]] ||
    die "Expected vfat at $ESP_PATH, found: $filesystem_type"

  partition_type="$(
    lsblk \
      --noheadings \
      --nodeps \
      --output PARTTYPE \
      "$(findmnt --noheadings --output SOURCE --target "$ESP_PATH")" |
      xargs |
      tr '[:lower:]' '[:upper:]'
  )"

  [[ "$partition_type" == "$expected_partition_type" ]] ||
    die "Mounted partition is not marked as an EFI System Partition."
}

validate_boot_files() {
  local required_files=(
    "${ESP_PATH}${KERNEL_IMAGE}"
    "${ESP_PATH}${MICROCODE_IMAGE}"
    "${ESP_PATH}${INITRAMFS_IMAGE}"
    "${ESP_PATH}${FALLBACK_INITRAMFS_IMAGE}"
  )

  local path

  for path in "${required_files[@]}"; do
    [[ -s "$path" ]] ||
      die "Required boot file is missing or empty: $path"
  done
}

discover_root_devices() {
  local root_source
  local mapper_name

  root_source="$(
    findmnt \
      --noheadings \
      --output SOURCE \
      --target / |
      sed 's/\[.*\]$//' |
      xargs
  )"

  [[ -b "$root_source" ]] ||
    die "Unable to identify the root block device."

  mapper_name="$(basename "$root_source")"

  [[ "$mapper_name" == "cryptroot" ]] ||
    die "Expected root mapper name cryptroot, found: $mapper_name"

  cryptsetup status "$mapper_name" >/dev/null 2>&1 ||
    die "Root filesystem is not backed by an active cryptsetup mapping."

  ROOT_DEVICE="$root_source"

  LUKS_DEVICE="$(
    cryptsetup status "$mapper_name" |
      awk '$1 == "device:" { print $2; exit }'
  )"

  [[ -n "$LUKS_DEVICE" ]] ||
    die "Unable to identify the LUKS backing partition."

  [[ -b "$LUKS_DEVICE" ]] ||
    die "LUKS backing device is not a block device: $LUKS_DEVICE"
}

discover_uuids() {
  LUKS_UUID="$(
    cryptsetup luksUUID "$LUKS_DEVICE"
  )"

  ROOT_UUID="$(
    blkid \
      --match-tag UUID \
      --output value \
      "$ROOT_DEVICE"
  )"

  [[ -n "$LUKS_UUID" ]] ||
    die "Unable to determine the LUKS UUID."

  [[ -n "$ROOT_UUID" ]] ||
    die "Unable to determine the Btrfs filesystem UUID."

  [[ "$LUKS_UUID" =~ ^[0-9a-fA-F-]{36}$ ]] ||
    die "Unexpected LUKS UUID format."

  [[ "$ROOT_UUID" =~ ^[0-9a-fA-F-]{36}$ ]] ||
    die "Unexpected root filesystem UUID format."
}

validate_root_filesystem() {
  local filesystem_type
  local filesystem_root

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target / |
      xargs
  )"

  filesystem_root="$(
    findmnt \
      --noheadings \
      --output FSROOT \
      --target / |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs root filesystem."

  [[ "$filesystem_root" == "/@" ]] ||
    die "Expected @ as the root Btrfs subvolume."
}

show_plan() {
  cat <<EOF

Bootloader configuration
------------------------

Implementation: systemd-boot
ESP:            $ESP_PATH
Default entry:  ${ENTRY_ID}.conf
Fallback entry: ${ENTRY_ID}-fallback.conf
Menu timeout:   ${LOADER_TIMEOUT} seconds

Encrypted root
--------------

LUKS device:    $LUKS_DEVICE
LUKS UUID:      $LUKS_UUID
Mapper name:    cryptroot

Root filesystem
---------------

Device:         $ROOT_DEVICE
Btrfs UUID:     $ROOT_UUID
Root subvolume: @

Kernel command line
-------------------

rd.luks.name=${LUKS_UUID}=cryptroot
rd.luks.options=${LUKS_UUID}=discard
root=UUID=${ROOT_UUID}
rootfstype=btrfs
rootflags=subvol=@
rw
EOF
}

confirm_installation() {
  local confirmation

  printf '\nType BOOTLOADER to install and configure systemd-boot: '
  read -r confirmation

  [[ "$confirmation" == "BOOTLOADER" ]] ||
    die "Bootloader installation was not authorized."
}

install_systemd_boot() {
  log "Installing systemd-boot on $ESP_PATH."

  bootctl \
    --esp-path="$ESP_PATH" \
    install
}

write_loader_configuration() {
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
default ${ENTRY_ID}.conf
timeout ${LOADER_TIMEOUT}
console-mode keep
editor no
EOF

  install \
    --directory \
    --owner root \
    --group root \
    --mode 0755 \
    "${ESP_PATH}/${LOADER_DIRECTORY}"

  install \
    --owner root \
    --group root \
    --mode 0644 \
    "$temporary_file" \
    "$LOADER_CONFIG"

  rm -f "$temporary_file"
  trap - RETURN
}

write_boot_entry() {
  local output_file=$1
  local title=$2
  local initramfs=$3
  local temporary_file

  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN

  cat >"$temporary_file" <<EOF
title   ${title}
linux   ${KERNEL_IMAGE}
initrd  ${MICROCODE_IMAGE}
initrd  ${initramfs}
options rd.luks.name=${LUKS_UUID}=cryptroot rd.luks.options=${LUKS_UUID}=discard root=UUID=${ROOT_UUID} rootfstype=btrfs rootflags=subvol=@ rw
EOF

  install \
    --directory \
    --owner root \
    --group root \
    --mode 0755 \
    "${ESP_PATH}/${ENTRY_DIRECTORY}"

  install \
    --owner root \
    --group root \
    --mode 0644 \
    "$temporary_file" \
    "$output_file"

  rm -f "$temporary_file"
  trap - RETURN
}

write_boot_entries() {
  log "Writing default boot entry."

  write_boot_entry \
    "$DEFAULT_ENTRY_FILE" \
    "$ENTRY_TITLE" \
    "$INITRAMFS_IMAGE"

  log "Writing fallback boot entry."

  write_boot_entry \
    "$FALLBACK_ENTRY_FILE" \
    "${ENTRY_TITLE} (fallback initramfs)" \
    "$FALLBACK_INITRAMFS_IMAGE"
}

validate_systemd_boot_installation() {
  bootctl \
    --esp-path="$ESP_PATH" \
    is-installed >/dev/null ||
    die "systemd-boot was not installed successfully."

  [[ -s "${ESP_PATH}/EFI/systemd/systemd-bootx64.efi" ]] ||
    die "Primary systemd-boot EFI binary is missing."

  [[ -s "${ESP_PATH}/EFI/BOOT/BOOTX64.EFI" ]] ||
    die "Fallback EFI boot binary is missing."
}

validate_loader_configuration() {
  [[ -s "$LOADER_CONFIG" ]] ||
    die "loader.conf was not created."

  grep -Fxq "default ${ENTRY_ID}.conf" "$LOADER_CONFIG" ||
    die "Default loader entry is incorrect."

  grep -Fxq "timeout ${LOADER_TIMEOUT}" "$LOADER_CONFIG" ||
    die "Loader timeout is incorrect."

  grep -Fxq 'console-mode keep' "$LOADER_CONFIG" ||
    die "Loader console mode is missing."

  grep -Fxq 'editor no' "$LOADER_CONFIG" ||
    die "Boot entry editing was not disabled."
}

validate_entry_file() {
  local entry_file=$1
  local expected_initramfs=$2

  grep -Fq "rd.luks.options=${LUKS_UUID}=discard" "$entry_file" ||
    die "LUKS discard option is missing from: $entry_file"

  [[ -s "$entry_file" ]] ||
    die "Boot entry is missing or empty: $entry_file"

  grep -Eq '^title[[:space:]]+.+' "$entry_file" ||
    die "Boot entry title is missing: $entry_file"

  grep -Eq "^[[:space:]]*linux[[:space:]]+${KERNEL_IMAGE}$" \
    "$entry_file" ||
    die "Kernel path is incorrect in: $entry_file"

  grep -Eq "^[[:space:]]*initrd[[:space:]]+${MICROCODE_IMAGE}$" \
    "$entry_file" ||
    die "Microcode image is missing from: $entry_file"

  grep -Eq "^[[:space:]]*initrd[[:space:]]+${expected_initramfs}$" \
    "$entry_file" ||
    die "Initramfs path is incorrect in: $entry_file"

  grep -Fq "rd.luks.name=${LUKS_UUID}=cryptroot" "$entry_file" ||
    die "LUKS mapping parameter is missing from: $entry_file"

  grep -Fq "root=UUID=${ROOT_UUID}" "$entry_file" ||
    die "Root filesystem UUID is missing from: $entry_file"

  grep -Fq 'rootfstype=btrfs' "$entry_file" ||
    die "Root filesystem type is missing from: $entry_file"

  grep -Fq 'rootflags=subvol=@' "$entry_file" ||
    die "Root subvolume parameter is missing from: $entry_file"

  grep -Eq '(^|[[:space:]])rw($|[[:space:]])' "$entry_file" ||
    die "Writable root parameter is missing from: $entry_file"
}

validate_configuration_files() {
  local path

  for path in \
    "$LOADER_CONFIG" \
    "$DEFAULT_ENTRY_FILE" \
    "$FALLBACK_ENTRY_FILE"; do

    [[ -f "$path" ]] ||
      die "Expected boot configuration file is missing: $path"

    [[ -r "$path" ]] ||
      die "Boot configuration file is not readable: $path"

    [[ -s "$path" ]] ||
      die "Boot configuration file is empty: $path"
  done
}

validate_boot_entries() {
  bootctl \
    --esp-path="$ESP_PATH" \
    list >/dev/null ||
    die "bootctl could not parse the configured boot entries."

  validate_entry_file \
    "$DEFAULT_ENTRY_FILE" \
    "$INITRAMFS_IMAGE"

  validate_entry_file \
    "$FALLBACK_ENTRY_FILE" \
    "$FALLBACK_INITRAMFS_IMAGE"
}

show_result() {
  printf '\nsystemd-boot installed and configured successfully.\n\n'

  bootctl \
    --esp-path="$ESP_PATH" \
    status \
    --no-pager || true

  printf '\nLoader configuration:\n\n'
  sed 's/^/  /' "$LOADER_CONFIG"

  printf '\nDefault boot entry:\n\n'
  sed 's/^/  /' "$DEFAULT_ENTRY_FILE"

  printf '\nFallback boot entry:\n\n'
  sed 's/^/  /' "$FALLBACK_ENTRY_FILE"

  printf '\nNext step:\n'
  printf '  18-first-boot\n'
}

main() {
  require_root
  require_commands
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
  write_loader_configuration
  write_boot_entries
  validate_systemd_boot_installation
  validate_loader_configuration
  validate_boot_entries
  validate_configuration_files
  show_result
}

main "$@"
