#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly DEFAULT_USERNAME="rafael"
readonly DEFAULT_FULL_NAME="Rafael"
readonly DEFAULT_SHELL="/bin/bash"
readonly SUDOERS_FILE="/etc/sudoers.d/10-wheel"

USERNAME="$DEFAULT_USERNAME"
FULL_NAME="$DEFAULT_FULL_NAME"
LOGIN_SHELL="$DEFAULT_SHELL"

CREATE_ROOT_PASSWORD=true
USER_ALREADY_EXISTS=false

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
  --username <name>
      Login name of the primary user.
      Default: ${DEFAULT_USERNAME}

  --full-name <name>
      Descriptive full name stored in the account.
      Default: ${DEFAULT_FULL_NAME}

  --shell <path>
      Initial login shell.
      Default: ${DEFAULT_SHELL}

  --no-root-password
      Do not configure a root password.

  --help, -h
      Show this help message.

Examples:
  ./$SCRIPT_NAME

  ./$SCRIPT_NAME \
    --username rafael \
    --full-name "Rafael" \
    --shell /bin/bash

Passwords are requested interactively and are never received through
command-line arguments, environment variables or profile files.

This script must run inside the installed Arch Linux system.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    getent
    grep
    id
    install
    passwd
    pacman
    stat
    su
    useradd
    usermod
    visudo
    awk
    chmod
    cut
    mktemp
    tr
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
      --username)
        (($# >= 2)) ||
          die "Missing value for --username."

        USERNAME="$2"
        shift 2
        ;;

      --full-name)
        (($# >= 2)) ||
          die "Missing value for --full-name."

        FULL_NAME="$2"
        shift 2
        ;;

      --shell)
        (($# >= 2)) ||
          die "Missing value for --shell."

        LOGIN_SHELL="$2"
        shift 2
        ;;

      --no-root-password)
        CREATE_ROOT_PASSWORD=false
        shift
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

validate_execution_context() {
  [[ -f /etc/os-release ]] ||
    die "The current root does not contain /etc/os-release."

  grep -q '^ID=arch$' /etc/os-release ||
    die "This script must run inside the installed Arch Linux system."

  [[ -s /etc/fstab ]] ||
    die "The installed-system fstab is missing or empty."
}

validate_sudo_package() {
  pacman -Q sudo >/dev/null 2>&1 ||
    die "The sudo package is not installed."

  [[ -x /usr/bin/sudo ]] ||
    die "The sudo executable is unavailable."

  [[ -x /usr/sbin/visudo || -x /usr/bin/visudo ]] ||
    die "The visudo executable is unavailable."
}

validate_username() {
  [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*\$?$ ]] ||
    die "Username contains unsupported characters."

  ((${#USERNAME} <= 32)) ||
    die "Username cannot exceed 32 characters."

  [[ "$USERNAME" != "root" ]] ||
    die "The primary user cannot be named root."
}

validate_full_name() {
  [[ -n "$FULL_NAME" ]] ||
    die "Full name cannot be empty."

  [[ "$FULL_NAME" != *:* ]] ||
    die "Full name cannot contain a colon."

  [[ "$FULL_NAME" != *$'\n'* ]] ||
    die "Full name cannot contain line breaks."
}

validate_shell() {
  [[ "$LOGIN_SHELL" == /* ]] ||
    die "Login shell must be an absolute path."

  [[ -x "$LOGIN_SHELL" ]] ||
    die "Login shell is not executable: $LOGIN_SHELL"

  grep -Fxq "$LOGIN_SHELL" /etc/shells ||
    die "Login shell is not registered in /etc/shells: $LOGIN_SHELL"
}

validate_wheel_group() {
  getent group wheel >/dev/null ||
    die "The wheel group does not exist."
}

inspect_existing_user() {
  if ! id "$USERNAME" >/dev/null 2>&1; then
    return
  fi

  USER_ALREADY_EXISTS=true

  local existing_uid

  existing_uid="$(id -u "$USERNAME")"

  ((existing_uid >= 1000)) ||
    die "Existing account does not appear to be a regular user: $USERNAME"

  warn "User already exists and will be validated instead of recreated."
}

show_plan() {
  cat <<EOF

Primary user
------------

Username:   $USERNAME
Full name:  $FULL_NAME
Home:       /home/$USERNAME
Shell:      $LOGIN_SHELL
Admin group: wheel

Authentication
--------------

User password: requested interactively
Root password: $(if [[ "$CREATE_ROOT_PASSWORD" == true ]]; then
  printf 'requested interactively'
else
  printf 'left unchanged'
fi)

Sudo policy
-----------

File: $SUDOERS_FILE
Rule: %wheel ALL=(ALL:ALL) ALL

No password or password hash will be stored by this script.
EOF

  if [[ "$USER_ALREADY_EXISTS" == true ]]; then
    printf '\nExisting user mode: validate and reconcile\n'
  else
    printf '\nExisting user mode: create account\n'
  fi
}

confirm_configuration() {
  local confirmation

  printf '\nType USER to configure the primary user: '
  read -r confirmation

  [[ "$confirmation" == "USER" ]] ||
    die "User configuration was not authorized."
}

create_user() {
  if [[ "$USER_ALREADY_EXISTS" == true ]]; then
    return
  fi

  log "Creating user: $USERNAME"

  useradd \
    --create-home \
    --user-group \
    --groups wheel \
    --comment "$FULL_NAME" \
    --shell "$LOGIN_SHELL" \
    "$USERNAME"
}

reconcile_existing_user() {
  if [[ "$USER_ALREADY_EXISTS" == false ]]; then
    return
  fi

  log "Reconciling existing user configuration."

  usermod \
    --append \
    --groups wheel \
    --comment "$FULL_NAME" \
    --shell "$LOGIN_SHELL" \
    "$USERNAME"
}

configure_user_password() {
  printf '\n'
  warn "You will now be prompted to define the password for $USERNAME."
  warn "The password is read directly by passwd and is not stored."
  printf '\n'

  passwd "$USERNAME"
}

configure_root_password() {
  if [[ "$CREATE_ROOT_PASSWORD" == false ]]; then
    return
  fi

  printf '\n'
  warn "You will now be prompted to define the root password."
  warn "The password is read directly by passwd and is not stored."
  printf '\n'

  passwd root
}

configure_sudoers() {
  local temporary_file

  temporary_file="$(mktemp)"

  trap 'rm -f "$temporary_file"' RETURN

  printf '%%wheel ALL=(ALL:ALL) ALL\n' >"$temporary_file"

  chmod 0440 "$temporary_file"

  visudo \
    --check \
    --file "$temporary_file" >/dev/null ||
    die "Generated sudoers policy is invalid."

  install \
    --owner root \
    --group root \
    --mode 0440 \
    "$temporary_file" \
    "$SUDOERS_FILE"

  rm -f "$temporary_file"
  trap - RETURN
}

validate_user_account() {
  id "$USERNAME" >/dev/null ||
    die "User account was not created."

  [[ "$(id -u "$USERNAME")" -ge 1000 ]] ||
    die "User does not have a regular-user UID."

  [[ "$(getent passwd "$USERNAME" | cut -d: -f6)" == "/home/$USERNAME" ]] ||
    die "User home directory is incorrect."

  [[ "$(getent passwd "$USERNAME" | cut -d: -f7)" == "$LOGIN_SHELL" ]] ||
    die "User login shell is incorrect."

  [[ -d "/home/$USERNAME" ]] ||
    die "User home directory does not exist."

  [[ "$(stat -c '%U' "/home/$USERNAME")" == "$USERNAME" ]] ||
    die "User does not own the home directory."

  [[ "$(stat -c '%G' "/home/$USERNAME")" == "$USERNAME" ]] ||
    die "Primary group does not own the home directory."
}

validate_wheel_membership() {
  id -nG "$USERNAME" |
    tr ' ' '\n' |
    grep -Fxq wheel ||
    die "User is not a member of the wheel group."
}

validate_password_state() {
  local user_state

  user_state="$(passwd --status "$USERNAME" | awk '{print $2}')"

  [[ "$user_state" == "P" ]] ||
    die "User password was not configured successfully."

  if [[ "$CREATE_ROOT_PASSWORD" == true ]]; then
    local root_state

    root_state="$(passwd --status root | awk '{print $2}')"

    [[ "$root_state" == "P" ]] ||
      die "Root password was not configured successfully."
  fi
}

validate_sudoers() {
  [[ -f "$SUDOERS_FILE" ]] ||
    die "Sudoers policy was not created."

  [[ "$(stat -c '%U:%G' "$SUDOERS_FILE")" == "root:root" ]] ||
    die "Sudoers policy ownership is incorrect."

  [[ "$(stat -c '%a' "$SUDOERS_FILE")" == "440" ]] ||
    die "Sudoers policy permissions are incorrect."

  visudo --check >/dev/null ||
    die "The complete sudoers configuration is invalid."

  grep -Fxq '%wheel ALL=(ALL:ALL) ALL' "$SUDOERS_FILE" ||
    die "Expected wheel sudo rule is missing."
}

validate_user_environment() {
  su \
    --login \
    "$USERNAME" \
    --command 'test "$HOME" = "/home/'"$USERNAME"'"' ||
    die "User login environment is not initialized correctly."
}

show_result() {
  printf '\nPrimary user configured successfully.\n\n'

  printf 'Account:\n'
  printf '  Username: %s\n' "$USERNAME"
  printf '  UID:      %s\n' "$(id -u "$USERNAME")"
  printf '  GID:      %s\n' "$(id -g "$USERNAME")"
  printf '  Home:     %s\n' "$(getent passwd "$USERNAME" | cut -d: -f6)"
  printf '  Shell:    %s\n' "$(getent passwd "$USERNAME" | cut -d: -f7)"

  printf '\nGroups:\n'
  printf '  %s\n' "$(id -nG "$USERNAME")"

  printf '\nSudo policy:\n'
  printf '  %s\n' "$SUDOERS_FILE"

  printf '\nNext step:\n'
  printf '  16-configure-initramfs\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_sudo_package
  validate_username
  validate_full_name
  validate_shell
  validate_wheel_group
  inspect_existing_user
  show_plan
  confirm_configuration
  create_user
  reconcile_existing_user
  configure_user_password
  configure_root_password
  configure_sudoers
  validate_user_account
  validate_wheel_membership
  validate_password_state
  validate_sudoers
  validate_user_environment
  show_result
}

main "$@"
