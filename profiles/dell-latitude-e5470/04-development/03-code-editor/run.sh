#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PACKAGE_FILE="${REPO_ROOT}/packages/development/code-editor-runtime.txt"
readonly SETTINGS_SOURCE="${REPO_ROOT}/dotfiles/vscode/settings.json"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/dotfiles/vscode/keybindings.json"
readonly EXTENSIONS_SOURCE="${REPO_ROOT}/dotfiles/vscode/extensions.txt"
readonly DESKTOP_SOURCE="${REPO_ROOT}/system/development/vscode/code.desktop"
readonly DOWNLOAD_URL="https://update.code.visualstudio.com/latest/linux-x64/stable"
readonly INSTALL_DIR="/opt/visual-studio-code"
readonly CODE_LINK="/usr/local/bin/code"
readonly DESKTOP_TARGET="/usr/share/applications/visual-studio-code.desktop"

TARGET_USER_ARG="${SUDO_USER:-}"
declare -a PACKAGES=()
declare -a MISSING_PACKAGES=()
TEMP_DIR=""

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/packages.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [--user <username>]

Installs the official Microsoft Visual Studio Code Linux x64 distribution
from:
  ${DOWNLOAD_URL}

Application destination:
  ${INSTALL_DIR}
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

run_as_target_user() {
  sudo -u "$TARGET_USER" -H "$@"
}

cleanup() {
  [[ -z "$TEMP_DIR" ]] || rm -rf -- "$TEMP_DIR"
}

show_plan() {
  printf '\nVisual Studio Code setup\n------------------------\n\n'
  printf 'Target user:\n  %s\n\n' "$TARGET_USER"
  printf 'Distribution:\n  Microsoft upstream stable Linux x64\n\n'
  printf 'Download endpoint:\n  %s\n\n' "$DOWNLOAD_URL"
  printf 'Install directory:\n  %s\n\n' "$INSTALL_DIR"
  printf 'Runtime packages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_changes() {
  local confirmation
  printf '\nType VSCODE to install/configure Visual Studio Code: '
  read -r confirmation
  [[ "$confirmation" == "VSCODE" ]] || die "Visual Studio Code setup was not authorized."
}

download_and_stage_vscode() {
  TEMP_DIR="$(mktemp -d)"
  trap cleanup EXIT

  log_info "Downloading Visual Studio Code from Microsoft."
  curl --fail --location --show-error --silent "$DOWNLOAD_URL" --output "${TEMP_DIR}/vscode.tar.gz"
  tar -xzf "${TEMP_DIR}/vscode.tar.gz" -C "$TEMP_DIR"

  [[ -x "${TEMP_DIR}/VSCode-linux-x64/bin/code" ]] || die "Downloaded archive does not contain the expected code launcher."
  [[ -f "${TEMP_DIR}/VSCode-linux-x64/resources/app/product.json" ]] || die "Downloaded archive does not look like Visual Studio Code."
}

install_vscode() {
  local staged="${TEMP_DIR}/VSCode-linux-x64"
  local next_dir="${INSTALL_DIR}.new"
  local old_dir="${INSTALL_DIR}.old"

  rm -rf -- "$next_dir" "$old_dir"
  cp -a -- "$staged" "$next_dir"
  chown -R root:root "$next_dir"

  if [[ -d "$INSTALL_DIR" ]]; then
    mv -- "$INSTALL_DIR" "$old_dir"
  fi

  mv -- "$next_dir" "$INSTALL_DIR"
  rm -rf -- "$old_dir"

  install -d -m 0755 /usr/local/bin /usr/share/applications
  ln -sfn "${INSTALL_DIR}/bin/code" "$CODE_LINK"
  install -m 0644 -o root -g root "$DESKTOP_SOURCE" "$DESKTOP_TARGET"
}

install_user_configuration() {
  local user_dir="${TARGET_HOME}/.config/Code/User"
  install_user_directory "${TARGET_HOME}/.config/Code"
  install_user_directory "$user_dir"
  install_user_file "$SETTINGS_SOURCE" "${user_dir}/settings.json"
  install_user_file "$KEYBINDINGS_SOURCE" "${user_dir}/keybindings.json"
}

install_extensions() {
  local extension

  while IFS= read -r extension; do
    extension="${extension%%#*}"
    extension="${extension//[[:space:]]/}"
    [[ -n "$extension" ]] || continue
    run_as_target_user "$CODE_LINK" --install-extension "$extension" --force >/dev/null
  done <"$EXTENSIONS_SOURCE"
}

validate_vscode() {
  [[ -x "${INSTALL_DIR}/bin/code" ]] || die "Visual Studio Code launcher is missing."
  [[ -L "$CODE_LINK" ]] || die "The code command symlink is missing."
  [[ -f "$DESKTOP_TARGET" ]] || die "Visual Studio Code desktop launcher is missing."
  cmp -s "$SETTINGS_SOURCE" "${TARGET_HOME}/.config/Code/User/settings.json" || die "VS Code settings differ from canonical source."
  cmp -s "$KEYBINDINGS_SOURCE" "${TARGET_HOME}/.config/Code/User/keybindings.json" || die "VS Code keybindings differ from canonical source."

  local version_output version
  version_output="$(run_as_target_user "$CODE_LINK" --version)"
  version="${version_output%%$'\n'*}"
  [[ -n "$version" ]] || die "Visual Studio Code did not return a version."

  local extension
  local installed_extensions
  installed_extensions="$(run_as_target_user "$CODE_LINK" --list-extensions)"
  while IFS= read -r extension; do
    extension="${extension%%#*}"
    extension="${extension//[[:space:]]/}"
    [[ -n "$extension" ]] || continue
    grep -Fxiq "$extension" <<<"$installed_extensions" || die "VS Code extension is missing: $extension"
  done <"$EXTENSIONS_SOURCE"

  printf '\nVisual Studio Code configured successfully.\n\nVersion:\n  %s\n' "$version"
  printf '\nDev Containers extension is installed; runtime integration will be validated after Docker configuration.\n'
  printf '\nNext step:\n  04-container-platform\n'
}

main() {
  require_root
  require_commands chown cmp cp curl install ln mktemp mv pacman rm sudo tar
  require_arch_systemd
  require_user_config_commands
  parse_arguments "$@"
  resolve_normal_user "$TARGET_USER_ARG"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages

  show_plan
  confirm_changes
  install_missing_packages
  validate_installed_packages
  download_and_stage_vscode
  install_vscode
  install_user_configuration
  install_extensions
  validate_vscode
}

main "$@"
