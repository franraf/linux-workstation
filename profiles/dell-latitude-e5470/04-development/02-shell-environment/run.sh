#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly PACKAGE_FILE="${REPO_ROOT}/packages/development/shell.txt"
readonly ZSH_SOURCE_ROOT="${REPO_ROOT}/system/development/zsh"
readonly STARSHIP_SOURCE="${REPO_ROOT}/system/development/starship/starship.toml"
readonly OH_MY_ZSH_REPOSITORY="https://github.com/ohmyzsh/ohmyzsh.git"

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

Package source:
  ${PACKAGE_FILE}

Canonical configuration:
  ${ZSH_SOURCE_ROOT}
  ${STARSHIP_SOURCE}
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --user)
        (($# >= 2)) || die "Missing value for --user."
        TARGET_USER_ARG="$2"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *) die "Unknown argument: $1" ;;
    esac
  done
  [[ -n "$TARGET_USER_ARG" ]] || die "Target user could not be inferred. Use --user <username>."
}

run_as_target_user() {
  sudo -u "$TARGET_USER" -H "$@"
}

confirm_changes() {
  local confirmation
  printf '\nShell environment setup\n-----------------------\n\nTarget user:\n  %s\n\n' "$TARGET_USER"
  printf 'Packages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
  printf '\nType SHELL to install/configure the shell environment: '
  read -r confirmation
  [[ "$confirmation" == "SHELL" ]] || die "Shell environment setup was not authorized."
}

install_oh_my_zsh() {
  local destination="${TARGET_HOME}/.local/share/oh-my-zsh"

  install_user_directory "${TARGET_HOME}/.local"
  install_user_directory "${TARGET_HOME}/.local/share"

  if [[ -d "$destination/.git" ]]; then
    local origin
    origin="$(run_as_target_user git -C "$destination" remote get-url origin 2>/dev/null || true)"
    [[ "$origin" == "$OH_MY_ZSH_REPOSITORY" || "$origin" == "https://github.com/ohmyzsh/ohmyzsh" ]] ||
      die "Existing Oh My Zsh checkout has an unexpected origin: ${origin:-unknown}"
    log_info "Existing Oh My Zsh checkout preserved: $destination"
    return 0
  fi

  [[ ! -e "$destination" ]] || die "Oh My Zsh destination exists but is not a Git checkout: $destination"
  run_as_target_user git clone --depth 1 "$OH_MY_ZSH_REPOSITORY" "$destination"
}

backup_if_changed() {
  local source="$1"
  local destination="$2"
  local backup="${destination}.pre-linux-workstation"

  [[ -e "$destination" ]] || return 0
  cmp -s "$source" "$destination" && return 0

  if [[ ! -e "$backup" ]]; then
    cp -a "$destination" "$backup"
    chown -R "$TARGET_USER:$TARGET_GROUP" "$backup"
    log_warn "Existing configuration backed up to: $backup"
  fi
}

install_shell_configuration() {
  local zsh_config_dir="${TARGET_HOME}/.config/zsh"
  local modules_dir="${zsh_config_dir}/modules"
  local starship_dir="${TARGET_HOME}/.config/starship"
  local module

  install_user_directory "${TARGET_HOME}/.config"
  install_user_directory "$zsh_config_dir"
  install_user_directory "$modules_dir"
  install_user_directory "$starship_dir"

  backup_if_changed "${ZSH_SOURCE_ROOT}/zshenv" "${TARGET_HOME}/.zshenv"
  backup_if_changed "${ZSH_SOURCE_ROOT}/zshrc" "${zsh_config_dir}/.zshrc"
  backup_if_changed "$STARSHIP_SOURCE" "${starship_dir}/starship.toml"

  install_user_file "${ZSH_SOURCE_ROOT}/zshenv" "${TARGET_HOME}/.zshenv"
  install_user_file "${ZSH_SOURCE_ROOT}/zshrc" "${zsh_config_dir}/.zshrc"
  install_user_file "$STARSHIP_SOURCE" "${starship_dir}/starship.toml"

  for module in environment.zsh aliases.zsh completion.zsh functions.zsh integrations.zsh prompt.zsh; do
    backup_if_changed "${ZSH_SOURCE_ROOT}/modules/${module}" "${modules_dir}/${module}"
    install_user_file "${ZSH_SOURCE_ROOT}/modules/${module}" "${modules_dir}/${module}"
  done
}

configure_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  [[ -n "$zsh_path" ]] || die "zsh executable was not found after installation."
  chsh -s "$zsh_path" "$TARGET_USER"
}

validate_shell_environment() {
  local configured_shell
  configured_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
  [[ "$configured_shell" == "$(command -v zsh)" ]] || die "Default shell validation failed for $TARGET_USER."

  cmp -s "${ZSH_SOURCE_ROOT}/zshenv" "${TARGET_HOME}/.zshenv" || die "Installed .zshenv differs from canonical source."
  cmp -s "${ZSH_SOURCE_ROOT}/zshrc" "${TARGET_HOME}/.config/zsh/.zshrc" || die "Installed .zshrc differs from canonical source."
  cmp -s "$STARSHIP_SOURCE" "${TARGET_HOME}/.config/starship/starship.toml" || die "Installed Starship configuration differs from canonical source."

  run_as_target_user env ZDOTDIR="${TARGET_HOME}/.config/zsh" zsh -ic 'command -v starship >/dev/null' ||
    die "Zsh/Starship integration validation failed."

  printf '\nShell environment configured successfully.\n\n'
  printf 'Default shell:\n  %s\n\n' "$configured_shell"
  printf 'Next step:\n  03-code-editor\n'
}

main() {
  require_root
  require_commands awk chown chsh cmp cp git install pacman sudo
  require_arch_systemd
  require_user_config_commands
  parse_arguments "$@"
  resolve_normal_user "$TARGET_USER_ARG"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages
  confirm_changes
  install_missing_packages
  validate_installed_packages

  require_commands starship zsh
  install_oh_my_zsh
  install_shell_configuration
  configure_default_shell
  validate_shell_environment
}

main "$@"
