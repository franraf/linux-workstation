#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/development/cli-tools.txt"

declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Package source:
  ${PACKAGE_FILE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

show_plan() {
  printf '\nCLI tools installation\n----------------------\n\n'
  printf 'Package source:\n  %s\n\n' "$PACKAGE_FILE"
  printf 'Packages to install:\n'
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
  printf '\nType CLI to install the missing command-line tools: '
  read -r confirmation
  [[ "$confirmation" == "CLI" ]] || die "CLI tools installation was not authorized."
}

validate_commands() {
  require_commands bat delta eza fd fzf http jq just lazygit make rg tmux yq
}

show_result() {
  printf '\nCLI tools installed successfully.\n\nInstalled package versions:\n\n'
  pacman -Q "${PACKAGES[@]}" | sed 's/^/  /'
  printf '\nNext step:\n  06-ai-tooling\n'
}

main() {
  require_root
  require_commands awk pacman sed
  require_arch_systemd
  parse_arguments "$@"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages

  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  validate_commands
  show_result
}

main "$@"
