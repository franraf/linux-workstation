#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly DEFAULT_PRIMARY_LOCALE="pt_BR.UTF-8"
readonly DEFAULT_FALLBACK_LOCALE="en_US.UTF-8"
readonly DEFAULT_CONSOLE_KEYMAP="br-abnt2"
readonly LOCALE_TEMPLATE="${REPO_ROOT}/system/localization/locale.conf.template"
readonly VCONSOLE_TEMPLATE="${REPO_ROOT}/system/localization/vconsole.conf.template"

PRIMARY_LOCALE="$DEFAULT_PRIMARY_LOCALE"
FALLBACK_LOCALE="$DEFAULT_FALLBACK_LOCALE"
CONSOLE_KEYMAP="$DEFAULT_CONSOLE_KEYMAP"

source "${REPO_ROOT}/scripts/lib/logging.sh"
source "${REPO_ROOT}/scripts/lib/requirements.sh"
source "${REPO_ROOT}/scripts/lib/installation.sh"

setup_error_trap "$SCRIPT_NAME"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [options]

Options:
  --primary-locale <locale>   Default: ${DEFAULT_PRIMARY_LOCALE}
  --fallback-locale <locale>  Default: ${DEFAULT_FALLBACK_LOCALE}
  --keymap <keymap>           Default: ${DEFAULT_CONSOLE_KEYMAP}
  --help, -h
EOF
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --primary-locale)
        (($# >= 2)) || die "Missing value for --primary-locale."
        PRIMARY_LOCALE="$2"
        shift 2
        ;;
      --fallback-locale)
        (($# >= 2)) || die "Missing value for --fallback-locale."
        FALLBACK_LOCALE="$2"
        shift 2
        ;;
      --keymap)
        (($# >= 2)) || die "Missing value for --keymap."
        CONSOLE_KEYMAP="$2"
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

validate_locale_name() {
  local locale_name="$1"
  [[ "$locale_name" =~ ^[a-z]{2}_[A-Z]{2}\.UTF-8$ ]] || die "Unsupported locale format: $locale_name"
}

locale_gen_entry() {
  printf '%s UTF-8' "$1"
}

validate_locale_available() {
  local locale_name="$1"
  local entry
  entry="$(locale_gen_entry "$locale_name")"
  grep -Eq "^[#[:space:]]*${entry//./\\.}[[:space:]]*$" /etc/locale.gen ||
    die "Locale is not available in /etc/locale.gen: $locale_name"
}

validate_keymap() {
  [[ "$CONSOLE_KEYMAP" =~ ^[a-zA-Z0-9._+-]+$ ]] || die "Console keymap contains unsupported characters."
  local keymap_file
  keymap_file="$(find /usr/share/kbd/keymaps -type f \( -name "${CONSOLE_KEYMAP}.map" -o -name "${CONSOLE_KEYMAP}.map.gz" \) -print -quit 2>/dev/null || true)"
  [[ -n "$keymap_file" ]] || die "Console keymap was not found: $CONSOLE_KEYMAP"
}

enable_locale() {
  local locale_name="$1"
  local escaped_locale="${locale_name//./\\.}"
  sed -Ei "s|^[#[:space:]]*(${escaped_locale}[[:space:]]+UTF-8)[[:space:]]*$|\1|" /etc/locale.gen
}

show_plan() {
  printf '\nLocalization configuration\n'
  printf '%s\n\n' '--------------------------'
  printf 'Primary locale:\n  %s\n\n' "$PRIMARY_LOCALE"
  printf 'Fallback locale:\n  %s\n\n' "$FALLBACK_LOCALE"
  printf 'Console keymap:\n  %s\n\n' "$CONSOLE_KEYMAP"
  printf 'Templates:\n  %s\n  %s\n' "$LOCALE_TEMPLATE" "$VCONSOLE_TEMPLATE"
}

confirm_configuration() {
  local confirmation
  printf '\nType LOCALE to apply the localization configuration: '
  read -r confirmation
  [[ "$confirmation" == "LOCALE" ]] || die "Localization configuration was not authorized."
}

configure_locale_generation() {
  enable_locale "$PRIMARY_LOCALE"
  [[ "$FALLBACK_LOCALE" == "$PRIMARY_LOCALE" ]] || enable_locale "$FALLBACK_LOCALE"
  locale-gen
}

render_template() {
  local source_file="$1"
  local target_file="$2"
  shift 2
  local temporary_file
  temporary_file="$(mktemp)"
  trap 'rm -f "$temporary_file"' RETURN
  cp "$source_file" "$temporary_file"

  local placeholder
  local value
  while (($# >= 2)); do
    placeholder="$1"
    value="$2"
    sed -i "s|${placeholder}|${value}|g" "$temporary_file"
    shift 2
  done

  install --mode 0644 "$temporary_file" "$target_file"
  rm -f "$temporary_file"
  trap - RETURN
}

configure_files() {
  render_template "$LOCALE_TEMPLATE" /etc/locale.conf '@PRIMARY_LOCALE@' "$PRIMARY_LOCALE"
  render_template "$VCONSOLE_TEMPLATE" /etc/vconsole.conf '@CONSOLE_KEYMAP@' "$CONSOLE_KEYMAP"
}

normalize_locale_name() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/utf-8/utf8/'
}

validate_generated_locale() {
  local normalized
  normalized="$(normalize_locale_name "$1")"
  local generated
  generated="$(localedef --list-archive | tr '[:upper:]' '[:lower:]')"
  grep -Fxq "$normalized" <<<"$generated" || die "Locale was not generated successfully: $1"
}

validate_configuration() {
  local locale_name
  local escaped
  for locale_name in "$PRIMARY_LOCALE" "$FALLBACK_LOCALE"; do
    escaped="${locale_name//./\\.}"
    grep -Eq "^${escaped}[[:space:]]+UTF-8[[:space:]]*$" /etc/locale.gen ||
      die "Locale remains disabled in /etc/locale.gen: $locale_name"
  done

  [[ "$(cat /etc/locale.conf)" == "LANG=$PRIMARY_LOCALE" ]] || die "/etc/locale.conf is incorrect."
  [[ "$(cat /etc/vconsole.conf)" == "KEYMAP=$CONSOLE_KEYMAP" ]] || die "/etc/vconsole.conf is incorrect."
  [[ "$(LANG="$PRIMARY_LOCALE" LC_ALL='' locale charmap)" == "UTF-8" ]] || die "Primary locale does not use UTF-8."
}

show_result() {
  printf '\nLocalization configured successfully.\n\n'
  printf '/etc/locale.conf:\n  %s\n' "$(cat /etc/locale.conf)"
  printf '/etc/vconsole.conf:\n  %s\n' "$(cat /etc/vconsole.conf)"
  printf '\nNext step:\n  14-configure-network\n'
}

main() {
  require_root
  require_commands cat cp find grep install locale locale-gen localedef mktemp sed tr
  parse_arguments "$@"
  require_installed_arch_context
  [[ -f /etc/locale.gen ]] || die "/etc/locale.gen is unavailable."
  [[ -s "$LOCALE_TEMPLATE" && -s "$VCONSOLE_TEMPLATE" ]] || die "Localization templates are missing."
  validate_locale_name "$PRIMARY_LOCALE"
  validate_locale_name "$FALLBACK_LOCALE"
  validate_locale_available "$PRIMARY_LOCALE"
  validate_locale_available "$FALLBACK_LOCALE"
  validate_keymap
  show_plan
  confirm_configuration
  configure_locale_generation
  configure_files
  validate_generated_locale "$PRIMARY_LOCALE"
  validate_generated_locale "$FALLBACK_LOCALE"
  validate_configuration
  show_result
}

main "$@"
