#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly DEFAULT_USERNAME="rafael"
readonly DEFAULT_FULL_NAME="Rafael"
readonly DEFAULT_SHELL="/bin/bash"
readonly SUDOERS_SOURCE="${REPO_ROOT}/system/sudoers/10-wheel"
readonly SUDOERS_FILE="/etc/sudoers.d/10-wheel"

USERNAME="$DEFAULT_USERNAME"
FULL_NAME="$DEFAULT_FULL_NAME"
LOGIN_SHELL="$DEFAULT_SHELL"
CREATE_ROOT_PASSWORD=true
USER_ALREADY_EXISTS=false

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [options]

Options:
  --username <name>      Default: ${DEFAULT_USERNAME}
  --full-name <name>     Default: ${DEFAULT_FULL_NAME}
  --shell <path>         Default: ${DEFAULT_SHELL}
  --no-root-password
  --help, -h

Passwords are requested interactively and are never stored by this script.
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --username) (($# >= 2)) || die "Missing value for --username."; USERNAME="$2"; shift 2 ;;
      --full-name) (($# >= 2)) || die "Missing value for --full-name."; FULL_NAME="$2"; shift 2 ;;
      --shell) (($# >= 2)) || die "Missing value for --shell."; LOGIN_SHELL="$2"; shift 2 ;;
      --no-root-password) CREATE_ROOT_PASSWORD=false; shift ;;
      --help | -h) usage; exit 0 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
}

validate_execution_context() {
  require_arch_linux
  [[ -s /etc/fstab ]] || die "The installed-system fstab is missing or empty."
  require_package_installed sudo "Install the base system package set first."
  [[ -s "$SUDOERS_SOURCE" ]] || die "Canonical sudoers policy is missing."
}

validate_account_inputs() {
  [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*\$?$ ]] || die "Username contains unsupported characters."
  ((${#USERNAME} <= 32)) || die "Username cannot exceed 32 characters."
  [[ "$USERNAME" != "root" ]] || die "The primary user cannot be named root."
  [[ -n "$FULL_NAME" && "$FULL_NAME" != *:* && "$FULL_NAME" != *$'\n'* ]] || die "Full name is invalid."
  [[ "$LOGIN_SHELL" == /* && -x "$LOGIN_SHELL" ]] || die "Login shell is not executable: $LOGIN_SHELL"
  grep -Fxq "$LOGIN_SHELL" /etc/shells || die "Login shell is not registered in /etc/shells: $LOGIN_SHELL"
  getent group wheel >/dev/null || die "The wheel group does not exist."
}

inspect_existing_user() {
  id "$USERNAME" >/dev/null 2>&1 || return 0
  USER_ALREADY_EXISTS=true
  (( $(id -u "$USERNAME") >= 1000 )) || die "Existing account does not appear to be a regular user: $USERNAME"
  log_warn "User already exists and will be reconciled instead of recreated."
}

show_plan() {
  printf '\nPrimary user configuration\n'
  printf '%s\n\n' '--------------------------'
  printf 'Username:\n  %s\n\n' "$USERNAME"
  printf 'Full name:\n  %s\n\n' "$FULL_NAME"
  printf 'Shell:\n  %s\n\n' "$LOGIN_SHELL"
  printf 'Sudo policy source:\n  %s\n\n' "$SUDOERS_SOURCE"
  printf 'Root password:\n  %s\n' "$( [[ "$CREATE_ROOT_PASSWORD" == true ]] && printf 'configure interactively' || printf 'leave unchanged' )"
}

confirm_configuration() {
  local confirmation
  printf '\nType USER to configure the primary user: '
  read -r confirmation
  [[ "$confirmation" == "USER" ]] || die "User configuration was not authorized."
}

configure_account() {
  if [[ "$USER_ALREADY_EXISTS" == false ]]; then
    useradd --create-home --user-group --groups wheel --comment "$FULL_NAME" --shell "$LOGIN_SHELL" "$USERNAME"
  else
    usermod --append --groups wheel --comment "$FULL_NAME" --shell "$LOGIN_SHELL" "$USERNAME"
  fi
}

configure_passwords() {
  log_warn "You will now be prompted to define the password for $USERNAME."
  passwd "$USERNAME"

  if [[ "$CREATE_ROOT_PASSWORD" == true ]]; then
    log_warn "You will now be prompted to define the root password."
    passwd root
  fi
}

configure_sudoers() {
  visudo --check --file "$SUDOERS_SOURCE" >/dev/null || die "Canonical sudoers policy is invalid."
  install --owner root --group root --mode 0440 "$SUDOERS_SOURCE" "$SUDOERS_FILE"
  visudo --check >/dev/null || die "The complete sudoers configuration is invalid."
}

validate_account() {
  id "$USERNAME" >/dev/null || die "User account was not created."
  (( $(id -u "$USERNAME") >= 1000 )) || die "User does not have a regular-user UID."
  [[ "$(getent passwd "$USERNAME" | cut -d: -f6)" == "/home/$USERNAME" ]] || die "User home directory is incorrect."
  [[ "$(getent passwd "$USERNAME" | cut -d: -f7)" == "$LOGIN_SHELL" ]] || die "User login shell is incorrect."
  [[ "$(stat -c '%U:%G' "/home/$USERNAME")" == "$USERNAME:$USERNAME" ]] || die "User home ownership is incorrect."

  local groups
  groups=" $(id -nG "$USERNAME") "
  [[ "$groups" == *" wheel "* ]] || die "User is not a member of the wheel group."

  [[ "$(passwd --status "$USERNAME" | awk '{print $2}')" == "P" ]] || die "User password was not configured successfully."
  if [[ "$CREATE_ROOT_PASSWORD" == true ]]; then
    [[ "$(passwd --status root | awk '{print $2}')" == "P" ]] || die "Root password was not configured successfully."
  fi
  [[ "$(stat -c '%U:%G:%a' "$SUDOERS_FILE")" == "root:root:440" ]] || die "Sudoers policy metadata is incorrect."
  cmp -s "$SUDOERS_SOURCE" "$SUDOERS_FILE" || die "Installed sudoers policy differs from canonical source."
  su --login "$USERNAME" --command 'test "$HOME" = "/home/'"$USERNAME"'"' || die "User login environment is not initialized correctly."
}

show_result() {
  printf '\nPrimary user configured successfully.\n\n'
  printf 'Account:\n  %s (UID %s)\n' "$USERNAME" "$(id -u "$USERNAME")"
  printf 'Groups:\n  %s\n' "$(id -nG "$USERNAME")"
  printf 'Sudo policy:\n  %s\n' "$SUDOERS_FILE"
  printf '\nNext step:\n  16-configure-initramfs\n'
}

main() {
  require_root
  require_commands awk cmp cut getent grep id install passwd stat su useradd usermod visudo
  parse_arguments "$@"
  validate_execution_context
  validate_account_inputs
  inspect_existing_user
  show_plan
  confirm_configuration
  configure_account
  configure_passwords
  configure_sudoers
  validate_account
  show_result
}

main "$@"
