#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly PREFERENCES_SOURCE="${REPO_ROOT}/system/thunar/preferences.tsv"
readonly KEYBINDINGS_SOURCE="${REPO_ROOT}/system/hyprland/modules/70-keybindings.lua"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Applies the shared Thunar preferences and installs the canonical Hyprland file-manager binding.
EOF
}

apply_thunar_preferences() {
  log_info "Applying Thunar preferences for ${TARGET_USER}."

  runuser -u "$TARGET_USER" -- env PREFERENCES_SOURCE="$PREFERENCES_SOURCE" dbus-run-session -- bash <<'EOF'
set -Eeuo pipefail

while IFS=$'\t' read -r property type value; do
  [[ -n "$property" ]] || continue
  [[ "$property" == \#* ]] && continue

  if ! xfconf-query -c thunar -p "$property" -t "$type" -s "$value" >/dev/null 2>&1; then
    xfconf-query -c thunar -p "$property" -n -t "$type" -s "$value" >/dev/null
  fi
done < "$PREFERENCES_SOURCE"
EOF
}

install_keybindings() {
  local hypr_directory
  hypr_directory="$(user_config_path hypr)"

  install_user_directory "$hypr_directory"
  install_user_directory "$hypr_directory/modules"
  install_user_file "$KEYBINDINGS_SOURCE" "$hypr_directory/modules/70-keybindings.lua"
}

validate_configuration() {
  local keybindings output
  keybindings="$(user_config_path hypr/modules/70-keybindings.lua)"

  grep -Fq 'hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))' "$keybindings" || die "SUPER+E file manager binding is missing."

  output="$(runuser -u "$TARGET_USER" -- dbus-run-session -- xfconf-query -c thunar -p /last-view 2>/dev/null)" || die "Could not query Thunar preferences."
  [[ "$output" == "ThunarDetailsView" ]] || die "Unexpected Thunar default view: $output"
}

show_result() {
  printf '\nThunar file manager configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Default view:\n  detailed list\n\n'
  printf 'Integrations validated:\n  gvfs, tumbler, thunar-volman\n\n'
  printf 'Binding:\n  SUPER + E -> thunar\n\n'
  printf 'Existing MIME associations were not modified.\n'
  printf '\nNext step:\n  20-configure-appearance\n'
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands bash dbus-run-session env grep runuser xfconf-query
  require_user_config_commands
  require_arch_systemd
  require_package_installed thunar "Run 09-install-file-manager first."
  require_package_installed gvfs "Run 09-install-file-manager first."
  require_package_installed tumbler "Run 09-install-file-manager first."
  require_package_installed thunar-volman "Run 09-install-file-manager first."
  require_package_installed hyprland "Run 02-install-compositor first."

  resolve_normal_user "$1"

  [[ -s "$PREFERENCES_SOURCE" ]] || die "Shared Thunar preferences are missing."
  [[ -s "$KEYBINDINGS_SOURCE" ]] || die "Shared Hyprland keybindings module is missing."

  apply_thunar_preferences
  install_keybindings
  validate_configuration
  show_result
}

main "$@"
