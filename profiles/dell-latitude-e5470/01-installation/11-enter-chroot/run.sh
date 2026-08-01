```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TARGET_ROOT="/mnt"
readonly DEFAULT_SHELL="/bin/bash"

TARGET_ROOT="$DEFAULT_TARGET_ROOT"
TARGET_SHELL="$DEFAULT_SHELL"

declare -a CHROOT_COMMAND=()

log() {
  printf '[INFO] %s\n' "$*"
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
  sudo ./$SCRIPT_NAME [options] [-- command [arguments...]]

Options:
  --root <path>
      Mounted target root.
      Default: ${DEFAULT_TARGET_ROOT}

  --shell <path>
      Interactive shell used when no command is provided.
      Default: ${DEFAULT_SHELL}

  --help, -h
      Show this help message.

Examples:
  sudo ./$SCRIPT_NAME

  sudo ./$SCRIPT_NAME --root /mnt

  sudo ./$SCRIPT_NAME -- pacman -Q

  sudo ./$SCRIPT_NAME -- \
    /root/linux-workstation/profiles/dell-latitude-e5470/\
01-installation/12-configure-time/run.sh

When no command is provided, an interactive shell is opened inside
the installed system.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    arch-chroot
    findmnt
    grep
    readlink
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
      --root)
        (($# >= 2)) ||
          die "Missing value for --root."

        TARGET_ROOT="$2"
        shift 2
        ;;

      --shell)
        (($# >= 2)) ||
          die "Missing value for --shell."

        TARGET_SHELL="$2"
        shift 2
        ;;

      --)
        shift
        CHROOT_COMMAND=("$@")
        break
        ;;

      --help | -h)
        usage
        exit 0
        ;;

      *)
        die "Unknown argument: $1. Use -- before the chroot command."
        ;;
    esac
  done
}

canonicalize_target_root() {
  [[ -e "$TARGET_ROOT" ]] ||
    die "Target root does not exist: $TARGET_ROOT"

  TARGET_ROOT="$(readlink -f "$TARGET_ROOT")"
}

validate_target_root() {
  [[ -d "$TARGET_ROOT" ]] ||
    die "Target root is not a directory: $TARGET_ROOT"

  [[ "$TARGET_ROOT" != "/" ]] ||
    die "Refusing to use the running root filesystem as the chroot target."

  findmnt --mountpoint "$TARGET_ROOT" >/dev/null 2>&1 ||
    die "Target root is not a mountpoint: $TARGET_ROOT"
}

validate_installed_system() {
  local required_paths=(
    "$TARGET_ROOT/etc/os-release"
    "$TARGET_ROOT/etc/fstab"
    "$TARGET_ROOT/usr/bin/bash"
    "$TARGET_ROOT/usr/bin/pacman"
    "$TARGET_ROOT/usr/bin/systemctl"
  )

  local path

  for path in "${required_paths[@]}"; do
    [[ -e "$path" ]] ||
      die "Required installed-system path is missing: $path"
  done

  grep -q '^ID=arch$' "$TARGET_ROOT/etc/os-release" ||
    die "Target system is not identified as Arch Linux."

  [[ -s "$TARGET_ROOT/etc/fstab" ]] ||
    die "Target fstab is missing or empty."
}

validate_mount_tree() {
  local required_mountpoints=(
    "$TARGET_ROOT"
    "$TARGET_ROOT/boot"
    "$TARGET_ROOT/home"
    "$TARGET_ROOT/var"
    "$TARGET_ROOT/var/log"
    "$TARGET_ROOT/var/cache"
    "$TARGET_ROOT/var/cache/pacman/pkg"
    "$TARGET_ROOT/var/lib/docker"
    "$TARGET_ROOT/.snapshots"
  )

  local mountpoint_path

  for mountpoint_path in "${required_mountpoints[@]}"; do
    findmnt --mountpoint "$mountpoint_path" >/dev/null 2>&1 ||
      die "Required mountpoint is missing: $mountpoint_path"
  done
}

validate_interactive_shell() {
  local shell_inside_target="${TARGET_ROOT}${TARGET_SHELL}"

  [[ "$TARGET_SHELL" == /* ]] ||
    die "Shell path must be absolute inside the target system."

  [[ -x "$shell_inside_target" ]] ||
    die "Shell is not executable inside the target: $TARGET_SHELL"
}

validate_command() {
  if ((${#CHROOT_COMMAND[@]} == 0)); then
    validate_interactive_shell
    return
  fi

  [[ -n "${CHROOT_COMMAND[0]}" ]] ||
    die "The chroot command cannot be empty."
}

show_summary() {
  cat <<EOF

Chroot target
-------------

Root: $TARGET_ROOT

EOF

  if ((${#CHROOT_COMMAND[@]} == 0)); then
    cat <<EOF
Execution mode
--------------

Mode:  interactive
Shell: $TARGET_SHELL
EOF
  else
    cat <<EOF
Execution mode
--------------

Mode:    command
Command:
EOF

    printf '  %q' "${CHROOT_COMMAND[@]}"
    printf '\n'
  fi
}

confirm_interactive_shell() {
  local confirmation

  printf '\nType CHROOT to enter the installed system: '
  read -r confirmation

  [[ "$confirmation" == "CHROOT" ]] ||
    die "Chroot transition was not authorized."
}

run_interactive_shell() {
  log "Opening interactive shell inside $TARGET_ROOT."

  arch-chroot \
    "$TARGET_ROOT" \
    "$TARGET_SHELL" \
    --login
}

run_command() {
  log "Executing command inside $TARGET_ROOT."

  arch-chroot \
    "$TARGET_ROOT" \
    "${CHROOT_COMMAND[@]}"
}

show_result() {
  if ((${#CHROOT_COMMAND[@]} == 0)); then
    printf '\nExited the chroot environment successfully.\n'
  else
    printf '\nChroot command completed successfully.\n'
  fi

  printf '\nNext step:\n'
  printf '  12-configure-time\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_target_root
  validate_target_root
  validate_installed_system
  validate_mount_tree
  validate_command
  show_summary

  if ((${#CHROOT_COMMAND[@]} == 0)); then
    confirm_interactive_shell
    run_interactive_shell
  else
    run_command
  fi

  show_result
}

main "$@"
```
