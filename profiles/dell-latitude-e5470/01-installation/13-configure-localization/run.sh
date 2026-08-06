#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly DEFAULT_PRIMARY_LOCALE="pt_BR.UTF-8"
readonly DEFAULT_FALLBACK_LOCALE="en_US.UTF-8"
readonly DEFAULT_CONSOLE_KEYMAP="br-abnt2"

PRIMARY_LOCALE="$DEFAULT_PRIMARY_LOCALE"
FALLBACK_LOCALE="$DEFAULT_FALLBACK_LOCALE"
CONSOLE_KEYMAP="$DEFAULT_CONSOLE_KEYMAP"

log() {
  printf '[INFO] %s\n' "$*"
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
  --primary-locale <locale>
      Primary system locale.
      Default: ${DEFAULT_PRIMARY_LOCALE}

  --fallback-locale <locale>
      Additional generated fallback locale.
      Default: ${DEFAULT_FALLBACK_LOCALE}

  --keymap <keymap>
      Persistent virtual-console keymap.
      Default: ${DEFAULT_CONSOLE_KEYMAP}

  --help, -h
      Show this help message.

Examples:
  ./$SCRIPT_NAME

  ./$SCRIPT_NAME \\
    --primary-locale pt_BR.UTF-8 \\
    --fallback-locale en_US.UTF-8 \\
    --keymap br-abnt2

This script must run inside the installed Arch Linux system.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    install
    locale
    locale-gen
    localedef
    sed
    find
    tr
    cat
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
      --primary-locale)
        (($# >= 2)) ||
          die "Missing value for --primary-locale."

        PRIMARY_LOCALE="$2"
        shift 2
        ;;

      --fallback-locale)
        (($# >= 2)) ||
          die "Missing value for --fallback-locale."

        FALLBACK_LOCALE="$2"
        shift 2
        ;;

      --keymap)
        (($# >= 2)) ||
          die "Missing value for --keymap."

        CONSOLE_KEYMAP="$2"
        shift 2
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

  [[ -f /etc/locale.gen ]] ||
    die "/etc/locale.gen is unavailable."
}

validate_locale_name() {
  local locale_name=$1

  [[ "$locale_name" =~ ^[a-z]{2}_[A-Z]{2}\.UTF-8$ ]] ||
    die "Unsupported locale format: $locale_name"
}

locale_gen_entry() {
  local locale_name=$1

  printf '%s UTF-8' "$locale_name"
}

validate_locale_available() {
  local locale_name=$1
  local entry

  entry="$(locale_gen_entry "$locale_name")"

  grep -Eq \
    "^[#[:space:]]*${entry//./\\.}[[:space:]]*$" \
    /etc/locale.gen ||
    die "Locale is not available in /etc/locale.gen: $locale_name"
}

validate_keymap() {
  [[ -n "$CONSOLE_KEYMAP" ]] ||
    die "Console keymap cannot be empty."

  [[ "$CONSOLE_KEYMAP" =~ ^[a-zA-Z0-9._+-]+$ ]] ||
    die "Console keymap contains unsupported characters."

  local keymap_file

  keymap_file="$(
    find /usr/share/kbd/keymaps \
      -type f \
      \( \
        -name "${CONSOLE_KEYMAP}.map" \
        -o -name "${CONSOLE_KEYMAP}.map.gz" \
      \) \
      -print \
      -quit 2>/dev/null || true
  )"

  [[ -n "$keymap_file" ]] ||
    die "Console keymap was not found: $CONSOLE_KEYMAP"
}

enable_locale() {
  local locale_name=$1
  local escaped_locale

  escaped_locale="${locale_name//./\\.}"

  log "Enabling locale: $locale_name"

  sed -Ei \
    "s|^[#[:space:]]*(${escaped_locale}[[:space:]]+UTF-8)[[:space:]]*$|\1|" \
    /etc/locale.gen
}

show_plan() {
  cat <<EOF

Localization configuration
--------------------------

Primary locale:  $PRIMARY_LOCALE
Fallback locale: $FALLBACK_LOCALE
Console keymap:  $CONSOLE_KEYMAP

Files
-----

/etc/locale.gen
/etc/locale.conf
/etc/vconsole.conf
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType LOCALE to apply the localization configuration: '
  read -r confirmation

  [[ "$confirmation" == "LOCALE" ]] ||
    die "Localization configuration was not authorized."
}

configure_locale_generation() {
  enable_locale "$PRIMARY_LOCALE"

  if [[ "$FALLBACK_LOCALE" != "$PRIMARY_LOCALE" ]]; then
    enable_locale "$FALLBACK_LOCALE"
  fi
}

generate_locales() {
  log "Generating configured locales."

  locale-gen
}

configure_locale_conf() {
  log "Writing /etc/locale.conf."

  printf 'LANG=%s\n' "$PRIMARY_LOCALE" |
    install \
      --mode 0644 \
      /dev/stdin \
      /etc/locale.conf
}

configure_vconsole() {
  log "Writing /etc/vconsole.conf."

  printf 'KEYMAP=%s\n' "$CONSOLE_KEYMAP" |
    install \
      --mode 0644 \
      /dev/stdin \
      /etc/vconsole.conf
}

normalize_locale_name() {
  local locale_name=$1

  printf '%s\n' "$locale_name" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/utf-8/utf8/'
}

validate_generated_locale() {
  local locale_name=$1
  local normalized_locale
  local generated_locales

  normalized_locale="$(normalize_locale_name "$locale_name")"

  generated_locales="$(
    localedef --list-archive |
      tr '[:upper:]' '[:lower:]'
  )"

  grep -Fxq "$normalized_locale" <<<"$generated_locales" ||
    die "Locale was not generated successfully: $locale_name"
}

validate_locale_gen_entries() {
  local locale_name
  local escaped_locale

  for locale_name in "$PRIMARY_LOCALE" "$FALLBACK_LOCALE"; do
    escaped_locale="${locale_name//./\\.}"

    grep -Eq \
      "^${escaped_locale}[[:space:]]+UTF-8[[:space:]]*$" \
      /etc/locale.gen ||
      die "Locale remains disabled in /etc/locale.gen: $locale_name"
  done
}

validate_locale_conf() {
  [[ -f /etc/locale.conf ]] ||
    die "/etc/locale.conf was not created."

  [[ "$(cat /etc/locale.conf)" == "LANG=$PRIMARY_LOCALE" ]] ||
    die "/etc/locale.conf does not contain the expected LANG value."
}

validate_vconsole_conf() {
  [[ -f /etc/vconsole.conf ]] ||
    die "/etc/vconsole.conf was not created."

  [[ "$(cat /etc/vconsole.conf)" == "KEYMAP=$CONSOLE_KEYMAP" ]] ||
    die "/etc/vconsole.conf does not contain the expected keymap."
}

validate_locale_environment() {
  local charmap

  charmap="$(
    LANG="$PRIMARY_LOCALE" \
      LC_ALL= \
      locale charmap
  )"

  [[ "$charmap" == "UTF-8" ]] ||
    die "Primary locale does not use UTF-8."
}

show_result() {
  printf '\nLocalization configured successfully.\n\n'

  printf '/etc/locale.conf:\n'
  sed 's/^/  /' /etc/locale.conf

  printf '\n/etc/vconsole.conf:\n'
  sed 's/^/  /' /etc/vconsole.conf

  printf '\nGenerated locales:\n'
  printf '  %s\n' "$PRIMARY_LOCALE"

  if [[ "$FALLBACK_LOCALE" != "$PRIMARY_LOCALE" ]]; then
    printf '  %s\n' "$FALLBACK_LOCALE"
  fi

  printf '\nNext step:\n'
  printf '  14-configure-network\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_locale_name "$PRIMARY_LOCALE"
  validate_locale_name "$FALLBACK_LOCALE"
  validate_locale_available "$PRIMARY_LOCALE"
  validate_locale_available "$FALLBACK_LOCALE"
  validate_keymap
  show_plan
  confirm_configuration
  configure_locale_generation
  generate_locales
  configure_locale_conf
  configure_vconsole
  validate_locale_gen_entries
  validate_generated_locale "$PRIMARY_LOCALE"
  validate_generated_locale "$FALLBACK_LOCALE"
  validate_locale_conf
  validate_vconsole_conf
  validate_locale_environment
  show_result
}

main "$@"
