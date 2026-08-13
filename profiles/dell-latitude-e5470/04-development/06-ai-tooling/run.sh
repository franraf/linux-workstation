#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/development/ai-tooling.txt"
readonly README_SOURCE="${REPO_ROOT}/dotfiles/ai/README.md"

TARGET_USER_ARG="${SUDO_USER:-}"
declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [--user <username>]

Installs the workstation AI tooling from official Arch Linux repositories.
Authentication is intentionally left to the normal user session.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --user) (($# >= 2)) || die "Missing value for --user."; TARGET_USER_ARG="$2"; shift 2 ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
  [[ -n "$TARGET_USER_ARG" ]] || die "Target user could not be inferred. Use --user <username>."
}

show_plan() {
  printf '\nAI tooling setup\n----------------\n\n'
  printf 'Target user:\n  %s\n\n' "$TARGET_USER"
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
  printf '\nType AI to install the declared AI tooling: '
  read -r confirmation
  [[ "$confirmation" == "AI" ]] || die "AI tooling installation was not authorized."
}

install_user_documentation() {
  local target_dir="${TARGET_HOME}/.config/linux-workstation/ai"
  install_user_directory "${TARGET_HOME}/.config/linux-workstation"
  install_user_directory "$target_dir"
  install_user_file "$README_SOURCE" "${target_dir}/README.md"
}

validate_tooling() {
  require_commands codex

  local version
  version="$(codex --version)"
  [[ -n "$version" ]] || die "Codex CLI did not return version information."

  printf '\nAI tooling installed successfully.\n\nCodex:\n  %s\n' "$version"
  printf '\nAuthentication is intentionally not automated.\n'
  printf 'From the normal user session, run:\n\n  codex --login\n'
  printf '\nNo API key or authentication secret is stored by this repository.\n'
  printf '\nNext step:\n  07-development-validation\n'
}

main() {
  require_root
  require_commands awk pacman sed
  require_arch_systemd
  require_user_config_commands
  parse_arguments "$@"
  resolve_normal_user "$TARGET_USER_ARG"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages

  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  install_user_documentation
  validate_tooling
}

main "$@"
