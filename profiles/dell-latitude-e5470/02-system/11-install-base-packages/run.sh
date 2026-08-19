#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_PACKAGE_FILE="${REPO_ROOT}/packages/system/base-workstation.txt"

PACKAGE_FILE="$DEFAULT_PACKAGE_FILE"
declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [--package-file <path>]

Default package source:
  ${DEFAULT_PACKAGE_FILE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --package-file)
        (($# >= 2)) || die "Missing value for --package-file."
        PACKAGE_FILE="$2"
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

show_plan() {
  printf '\nBase package installation\n-------------------------\n\nPackage file:\n  %s\n\nDeclared packages:\n' "$PACKAGE_FILE"
  printf '  - %s\n' "${PACKAGES[@]}"
  printf '\nPackages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_installation() {
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    return 0
  fi
  local confirmation
  printf '\nType PACKAGES to install the missing packages: '
  read -r confirmation
  [[ "$confirmation" == "PACKAGES" ]] || die "Base package installation was not authorized."
}

validate_expected_commands() {
  require_commands bash curl htop lsof rsync tree unzip wget zip
}

show_result() {
  printf '\nBase packages installed successfully.\n\nInstalled package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nNext step:\n  12-system-validation\n'
}

main() {
  require_root
  require_commands awk pacman sed
  parse_arguments "$@"
  require_arch_systemd
  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages
  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  validate_expected_commands
  show_result
}

main "$@"
