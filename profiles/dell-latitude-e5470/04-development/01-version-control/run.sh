#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/development/version-control.txt"

TARGET_USER_ARG="${SUDO_USER:-}"
GIT_NAME=""
GIT_EMAIL=""
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
  sudo ./$SCRIPT_NAME [--user <username>] [--name <git-name>] [--email <git-email>]

Package source:
  ${PACKAGE_FILE}

Identity values are only requested when the target user does not already
have user.name or user.email configured globally.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --user) (($# >= 2)) || die "Missing value for --user."; TARGET_USER_ARG="$2"; shift 2 ;;
      --name) (($# >= 2)) || die "Missing value for --name."; GIT_NAME="$2"; shift 2 ;;
      --email) (($# >= 2)) || die "Missing value for --email."; GIT_EMAIL="$2"; shift 2 ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done

  [[ -n "$TARGET_USER_ARG" ]] || die "Target user could not be inferred. Use --user <username>."
}

run_as_target_user() {
  sudo -u "$TARGET_USER" -H "$@"
}

resolve_git_identity() {
  local existing_name existing_email

  existing_name="$(run_as_target_user git config --global --get user.name 2>/dev/null || true)"
  existing_email="$(run_as_target_user git config --global --get user.email 2>/dev/null || true)"

  [[ -n "$GIT_NAME" ]] || GIT_NAME="$existing_name"
  [[ -n "$GIT_EMAIL" ]] || GIT_EMAIL="$existing_email"

  if [[ -z "$GIT_NAME" ]]; then
    printf 'Git user.name for %s: ' "$TARGET_USER"
    read -r GIT_NAME
  fi

  if [[ -z "$GIT_EMAIL" ]]; then
    printf 'Git user.email for %s: ' "$TARGET_USER"
    read -r GIT_EMAIL
  fi

  [[ -n "$GIT_NAME" ]] || die "Git user.name cannot be empty."
  [[ -n "$GIT_EMAIL" ]] || die "Git user.email cannot be empty."
}

show_plan() {
  printf '\nVersion control setup\n---------------------\n\n'
  printf 'Target user:\n  %s\n\n' "$TARGET_USER"
  printf 'Package source:\n  %s\n\n' "$PACKAGE_FILE"
  printf 'Git identity:\n  %s <%s>\n\n' "$GIT_NAME" "$GIT_EMAIL"
  printf 'Packages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_changes() {
  local confirmation
  printf '\nType GIT to install/configure version control: '
  read -r confirmation
  [[ "$confirmation" == "GIT" ]] || die "Version control setup was not authorized."
}

configure_git() {
  run_as_target_user git config --global user.name "$GIT_NAME"
  run_as_target_user git config --global user.email "$GIT_EMAIL"
  run_as_target_user git config --global init.defaultBranch main
}

prepare_ssh_directory() {
  install_user_directory "${TARGET_HOME}/.ssh" 0700
}

validate_git() {
  [[ "$(run_as_target_user git config --global --get user.name)" == "$GIT_NAME" ]] || die "Git user.name validation failed."
  [[ "$(run_as_target_user git config --global --get user.email)" == "$GIT_EMAIL" ]] || die "Git user.email validation failed."
  [[ "$(run_as_target_user git config --global --get init.defaultBranch)" == "main" ]] || die "Git default branch validation failed."

  local git_version
  git_version="$(git --version)"
  printf '\nGit configured successfully.\n\n%s\n' "$git_version"

  if compgen -G "${TARGET_HOME}/.ssh/*.pub" >/dev/null; then
    printf 'SSH public key detected for %s.\n' "$TARGET_USER"
  else
    log_warn "No SSH public key was found in ${TARGET_HOME}/.ssh. GitHub SSH authentication still requires a key to be created and registered."
  fi

  printf '\nNext step:\n  02-shell-environment\n'
}

main() {
  require_root
  require_commands awk git install pacman sudo
  require_arch_systemd
  require_user_config_commands
  parse_arguments "$@"
  resolve_normal_user "$TARGET_USER_ARG"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages

  resolve_git_identity
  show_plan
  confirm_changes
  install_missing_packages
  validate_installed_packages
  prepare_ssh_directory
  configure_git
  validate_git
}

main "$@"
