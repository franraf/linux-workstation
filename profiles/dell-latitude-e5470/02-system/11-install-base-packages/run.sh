#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

readonly DEFAULT_PACKAGE_FILE="${SCRIPT_DIRECTORY}/packages.txt"

PACKAGE_FILE="$DEFAULT_PACKAGE_FILE"

declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

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
  sudo ./$SCRIPT_NAME [options]

Options:
  --package-file <path>
      Package list to install.
      Default:
      ${DEFAULT_PACKAGE_FILE}

  --help, -h
      Show this help message.

The package file supports:

  - one package per line;
  - empty lines;
  - comments beginning with #.

Only packages considered part of the base workstation are managed here.

Development-specific CLI tools, SDKs and runtimes are intentionally
excluded and belong to later phases.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    awk
    grep
    pacman
    readlink
    sed
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
      --package-file)
        (($# >= 2)) ||
          die "Missing value for --package-file."

        PACKAGE_FILE="$2"
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
  PACKAGE_FILE="$(readlink -f "$PACKAGE_FILE")"
}

validate_execution_context() {
  [[ -f /etc/os-release ]] ||
    die "The current root does not contain /etc/os-release."

  grep -q '^ID=arch$' /etc/os-release ||
    die "This script must run on Arch Linux."

  [[ -d /run/systemd/system ]] ||
    die "systemd is not running as PID 1."
}

validate_package_file() {
  [[ -f "$PACKAGE_FILE" ]] ||
    die "Package file does not exist: $PACKAGE_FILE"

  [[ -r "$PACKAGE_FILE" ]] ||
    die "Package file is not readable: $PACKAGE_FILE"
}

load_packages() {
  mapfile -t PACKAGES < <(
    awk '
      {
        sub(/[[:space:]]*#.*/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      }

      length($0) > 0 {
        print
      }
    ' "$PACKAGE_FILE"
  )

  ((${#PACKAGES[@]} > 0)) ||
    die "Package file does not contain any packages."
}

validate_package_names() {
  local package

  for package in "${PACKAGES[@]}"; do
    [[ "$package" =~ ^[a-zA-Z0-9@._+-]+$ ]] ||
      die "Invalid package name: $package"
  done
}

validate_packages_available() {
  local package

  log "Validating package availability."

  for package in "${PACKAGES[@]}"; do
    pacman \
      --sync \
      --info \
      "$package" >/dev/null 2>&1 ||
      die "Package is unavailable from configured repositories: $package"
  done
}

discover_missing_packages() {
  local package

  MISSING_PACKAGES=()

  for package in "${PACKAGES[@]}"; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
      MISSING_PACKAGES+=("$package")
    fi
  done
}

show_plan() {
  cat <<EOF

Base package installation
-------------------------

Package file:
  $PACKAGE_FILE

Declared packages:
EOF

  printf '  - %s\n' "${PACKAGES[@]}"

  printf '\nAlready installed:\n'

  local package
  local installed_count=0

  for package in "${PACKAGES[@]}"; do
    if pacman -Q "$package" >/dev/null 2>&1; then
      printf '  - %s\n' "$package"
      ((installed_count += 1))
    fi
  done

  if ((installed_count == 0)); then
    printf '  none\n'
  fi

  printf '\nPackages to install:\n'

  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_installation() {
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    return
  fi

  local confirmation

  printf '\nType PACKAGES to install the missing packages: '
  read -r confirmation

  [[ "$confirmation" == "PACKAGES" ]] ||
    die "Base package installation was not authorized."
}

install_packages() {
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    log "All declared base packages are already installed."
    return
  fi

  log "Installing ${#MISSING_PACKAGES[@]} missing packages."

  pacman \
    --sync \
    --needed \
    "${MISSING_PACKAGES[@]}"
}

validate_installed_packages() {
  local package

  for package in "${PACKAGES[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 ||
      die "Package was not installed successfully: $package"
  done
}

validate_expected_commands() {
  local commands=(
    bash
    curl
    htop
    lsof
    rsync
    tree
    unzip
    wget
    zip
  )

  local command_name

  for command_name in "${commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      die "Expected command is unavailable after installation: $command_name"
  done
}

show_result() {
  printf '\nBase packages installed successfully.\n\n'

  printf 'Installed package versions:\n\n'

  pacman -Q "${PACKAGES[@]}" |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  12-system-validation\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_paths
  validate_execution_context
  validate_package_file
  load_packages
  validate_package_names
  validate_packages_available
  discover_missing_packages
  show_plan
  confirm_installation
  install_packages
  validate_installed_packages
  validate_expected_commands
  show_result
}

main "$@"
