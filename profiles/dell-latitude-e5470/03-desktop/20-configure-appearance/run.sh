#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"

readonly HYPR_APPEARANCE_SOURCE="${REPO_ROOT}/system/hyprland/modules/80-appearance.lua"
readonly GTK3_SOURCE="${REPO_ROOT}/system/gtk-3.0/settings.ini"
readonly GTK4_SOURCE="${REPO_ROOT}/system/gtk-4.0/settings.ini"
readonly WAYBAR_STYLE_SOURCE="${REPO_ROOT}/system/waybar/style.css"
readonly ROFI_CONFIG_SOURCE="${REPO_ROOT}/system/rofi/config.rasi"
readonly ROFI_THEME_SOURCE="${REPO_ROOT}/system/rofi/theme.rasi"
readonly SWAYNC_STYLE_SOURCE="${REPO_ROOT}/system/swaync/style.css"
readonly KITTY_CONFIG_SOURCE="${REPO_ROOT}/system/kitty/kitty.conf"
readonly KITTY_APPEARANCE_SOURCE="${REPO_ROOT}/system/kitty/appearance.conf"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/user-config.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <username>

Installs the shared visual baseline for the configured desktop components.
This step does not install packages, themes, icons, cursors or fonts.
EOF
}

validate_sources() {
  local source_file
  for source_file in \
    "$HYPR_APPEARANCE_SOURCE" \
    "$GTK3_SOURCE" \
    "$GTK4_SOURCE" \
    "$WAYBAR_STYLE_SOURCE" \
    "$ROFI_CONFIG_SOURCE" \
    "$ROFI_THEME_SOURCE" \
    "$SWAYNC_STYLE_SOURCE" \
    "$KITTY_CONFIG_SOURCE" \
    "$KITTY_APPEARANCE_SOURCE"; do
    [[ -s "$source_file" ]] || die "Shared appearance source is missing: $source_file"
  done
}

validate_resources() {
  log_info "Validating visual resources already available on the system."

  fc-match 'Noto Sans' >/dev/null 2>&1 || die "Noto Sans is unavailable. Run 10-install-font-stack first."
  fc-match 'JetBrainsMono Nerd Font' >/dev/null 2>&1 || die "JetBrainsMono Nerd Font is unavailable. Run 10-install-font-stack first."

  [[ -d /usr/share/icons/Adwaita ]] || log_warn "Adwaita icon theme directory was not found; GTK may fall back to another icon theme."
}

install_appearance() {
  local hypr_directory gtk3_directory gtk4_directory waybar_directory rofi_directory swaync_directory kitty_directory

  hypr_directory="$(user_config_path hypr)"
  gtk3_directory="$(user_config_path gtk-3.0)"
  gtk4_directory="$(user_config_path gtk-4.0)"
  waybar_directory="$(user_config_path waybar)"
  rofi_directory="$(user_config_path rofi)"
  swaync_directory="$(user_config_path swaync)"
  kitty_directory="$(user_config_path kitty)"

  log_info "Installing desktop appearance for ${TARGET_USER}."

  install_user_directory "$hypr_directory"
  install_user_directory "$hypr_directory/modules"
  install_user_directory "$gtk3_directory"
  install_user_directory "$gtk4_directory"
  install_user_directory "$waybar_directory"
  install_user_directory "$rofi_directory"
  install_user_directory "$swaync_directory"
  install_user_directory "$kitty_directory"

  install_user_file "$HYPR_APPEARANCE_SOURCE" "$hypr_directory/modules/80-appearance.lua"
  install_user_file "$GTK3_SOURCE" "$gtk3_directory/settings.ini"
  install_user_file "$GTK4_SOURCE" "$gtk4_directory/settings.ini"
  install_user_file "$WAYBAR_STYLE_SOURCE" "$waybar_directory/style.css"
  install_user_file "$ROFI_CONFIG_SOURCE" "$rofi_directory/config.rasi"
  install_user_file "$ROFI_THEME_SOURCE" "$rofi_directory/theme.rasi"
  install_user_file "$SWAYNC_STYLE_SOURCE" "$swaync_directory/style.css"
  install_user_file "$KITTY_CONFIG_SOURCE" "$kitty_directory/kitty.conf"
  install_user_file "$KITTY_APPEARANCE_SOURCE" "$kitty_directory/appearance.conf"
}

validate_installed_appearance() {
  local hypr_appearance rofi_config rofi_theme kitty_config kitty_appearance

  hypr_appearance="$(user_config_path hypr/modules/80-appearance.lua)"
  rofi_config="$(user_config_path rofi/config.rasi)"
  rofi_theme="$(user_config_path rofi/theme.rasi)"
  kitty_config="$(user_config_path kitty/kitty.conf)"
  kitty_appearance="$(user_config_path kitty/appearance.conf)"

  grep -Fq '["col.active_border"] = "#7aa2f7ff"' "$hypr_appearance" || die "Hyprland active border color is missing."
  grep -Fq '@theme "theme"' "$rofi_config" || die "Rofi theme is not referenced by config.rasi."
  grep -q '^include appearance.conf$' "$kitty_config" || die "Kitty appearance module is not included."
  grep -q '^background #1a1b26$' "$kitty_appearance" || die "Kitty background color is missing."

  runuser -u "$TARGET_USER" -- rofi -no-config -theme "$rofi_theme" -dump-theme >/dev/null 2>&1 || \
    die "Rofi could not parse the installed theme."
}

show_result() {
  printf '\nDesktop appearance configured successfully.\n\n'
  printf 'User:\n  %s\n\n' "$TARGET_USER"
  printf 'Baseline:\n'
  printf '  dark interface\n'
  printf '  blue accent (#7aa2f7)\n'
  printf '  Adwaita icons/cursor\n'
  printf '  Noto Sans + JetBrainsMono Nerd Font\n'
  printf '  solid compositor background (#1a1b26)\n\n'
  printf 'No package was installed by this step.\n'
  printf 'Visual consistency and Hyprland config errors must be validated from the graphical session.\n'
  printf '\nNext step:\n  21-configure-session-login\n'
}

main() {
  [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { usage; exit 0; }
  (($# == 1)) || die "Expected exactly one argument: username"

  require_root
  require_commands fc-match grep rofi runuser
  require_user_config_commands
  require_arch_systemd
  require_package_installed hyprland "Run 02-install-compositor first."
  require_package_installed waybar "Run 03-install-status-bar first."
  require_package_installed rofi "Run 06-install-application-launcher first."
  require_package_installed swaync "Run 07-install-notification-center first."
  require_package_installed kitty "Run 08-install-terminal-emulator first."

  resolve_normal_user "$1"
  validate_sources
  validate_resources
  install_appearance
  validate_installed_appearance
  show_result
}

main "$@"
