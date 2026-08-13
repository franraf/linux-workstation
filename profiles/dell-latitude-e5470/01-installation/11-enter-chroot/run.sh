#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly DEFAULT_TARGET_ROOT="/mnt"
readonly DEFAULT_SHELL="/bin/bash"
readonly LAYOUT_FILE="${REPO_ROOT}/system/storage/btrfs-layout.tsv"

TARGET_ROOT="$DEFAULT_TARGET_ROOT"
TARGET_SHELL="$DEFAULT_SHELL"
declare -a CHROOT_COMMAND=()
declare -a BTRFS_SUBVOLUMES=()
declare -a BTRFS_MOUNTPOINTS=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"
source "${REPO_ROOT}/scripts/lib/storage.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [options] [-- command [arguments...]]

Options:
  --root <path>   Default: ${DEFAULT_TARGET_ROOT}
  --shell <path>  Default: ${DEFAULT_SHELL}
  --help, -h
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --root) (($# >= 2)) || die "Missing value for --root."; TARGET_ROOT="$2"; shift 2 ;;
      --shell) (($# >= 2)) || die "Missing value for --shell."; TARGET_SHELL="$2"; shift 2 ;;
      --) shift; CHROOT_COMMAND=("$@"); break ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1. Use -- before the chroot command." ;;
    esac
  done
}

validate_target() {
  TARGET_ROOT="$(canonicalize_existing_path "$TARGET_ROOT")"
  require_btrfs_root_subvolume "$TARGET_ROOT" "/@"
  require_arch_target_system "$TARGET_ROOT"
  [[ -s "$TARGET_ROOT/etc/fstab" ]] || die "Target fstab is missing or empty."
  require_mountpoints "$TARGET_ROOT" "${BTRFS_MOUNTPOINTS[@]}" /boot

  local path
  for path in "$TARGET_ROOT/usr/bin/bash" "$TARGET_ROOT/usr/bin/pacman" "$TARGET_ROOT/usr/bin/systemctl"; do
    [[ -e "$path" ]] || die "Required installed-system path is missing: $path"
  done
}

validate_command() {
  if ((${#CHROOT_COMMAND[@]} == 0)); then
    [[ "$TARGET_SHELL" == /* ]] || die "Shell path must be absolute inside the target system."
    [[ -x "${TARGET_ROOT}${TARGET_SHELL}" ]] || die "Shell is not executable inside the target: $TARGET_SHELL"
  else
    [[ -n "${CHROOT_COMMAND[0]}" ]] || die "The chroot command cannot be empty."
  fi
}

show_summary() {
  printf '\nChroot transition\n'
  printf '%s\n\n' '-----------------'
  printf 'Root:\n  %s\n\n' "$TARGET_ROOT"
  if ((${#CHROOT_COMMAND[@]} == 0)); then
    printf 'Mode:\n  interactive (%s)\n' "$TARGET_SHELL"
  else
    printf 'Mode:\n  command\n\nCommand:\n '
    printf ' %q' "${CHROOT_COMMAND[@]}"
    printf '\n'
  fi
}

confirm_interactive_shell() {
  local confirmation
  printf '\nType CHROOT to enter the installed system: '
  read -r confirmation
  [[ "$confirmation" == "CHROOT" ]] || die "Chroot transition was not authorized."
}

run_chroot() {
  if ((${#CHROOT_COMMAND[@]} == 0)); then
    log_info "Opening interactive shell inside $TARGET_ROOT."
    arch-chroot "$TARGET_ROOT" "$TARGET_SHELL" --login
  else
    log_info "Executing command inside $TARGET_ROOT."
    arch-chroot "$TARGET_ROOT" "${CHROOT_COMMAND[@]}"
  fi
}

show_result() {
  printf '\nChroot operation completed successfully.\n'
  printf '\nNext step:\n  12-configure-time\n'
}

main() {
  require_root
  require_commands arch-chroot findmnt grep readlink xargs
  parse_arguments "$@"
  load_btrfs_layout "$LAYOUT_FILE"
  validate_target
  validate_command
  show_summary
  ((${#CHROOT_COMMAND[@]} > 0)) || confirm_interactive_shell
  run_chroot
  show_result
}

main "$@"
