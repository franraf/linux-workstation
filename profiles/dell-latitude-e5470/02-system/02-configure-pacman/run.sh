```bash
#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

readonly PACMAN_CONFIG="/etc/pacman.conf"
readonly PARALLEL_DOWNLOADS="5"

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
  sudo ./$SCRIPT_NAME

This script configures the system pacman configuration.

Managed options:

  Color
  VerbosePkgLists
  CheckSpace
  ParallelDownloads = ${PARALLEL_DOWNLOADS}

Configuration file:

  ${PACMAN_CONFIG}

The repository configuration and signature policies are preserved.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    grep
    pacman
    sed
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
    die "This script must run on Arch Linux."

  [[ -s /etc/fstab ]] ||
    die "The installed-system fstab is missing or empty."
}

validate_configuration_file() {
  [[ -f "$PACMAN_CONFIG" ]] ||
    die "Pacman configuration file does not exist."

  [[ -r "$PACMAN_CONFIG" ]] ||
    die "Pacman configuration file is not readable."

  [[ -w "$PACMAN_CONFIG" ]] ||
    die "Pacman configuration file is not writable."

  grep -Fxq '[options]' "$PACMAN_CONFIG" ||
    die "Pacman configuration does not contain an [options] section."

  grep -Eq '^\[core\]' "$PACMAN_CONFIG" ||
    die "Core repository configuration is missing."

  grep -Eq '^\[extra\]' "$PACMAN_CONFIG" ||
    die "Extra repository configuration is missing."
}

show_plan() {
  cat <<EOF

Pacman configuration
--------------------

File:
  ${PACMAN_CONFIG}

Options to enable
-----------------

Color
VerbosePkgLists
CheckSpace
ParallelDownloads = ${PARALLEL_DOWNLOADS}

Preserved configuration
-----------------------

Repository definitions
Mirrorlist includes
Signature policies
Architecture settings
Cache settings
EOF
}

confirm_configuration() {
  local confirmation

  printf '\nType PACMAN to apply the configuration: '
  read -r confirmation

  [[ "$confirmation" == "PACMAN" ]] ||
    die "Pacman configuration was not authorized."
}

enable_boolean_option() {
  local option=$1
  local escaped_option
  local match_count

  escaped_option="${option//./\\.}"

  match_count="$(
    grep -Ec \
      "^[#[:space:]]*${escaped_option}[[:space:]]*$" \
      "$PACMAN_CONFIG" ||
      true
  )"

  if ((match_count == 0)); then
    die "Pacman option was not found in the default configuration: $option"
  fi

  if ((match_count > 1)); then
    die "Multiple definitions found for pacman option: $option"
  fi

  sed -Ei \
    "s|^[#[:space:]]*${escaped_option}[[:space:]]*$|${option}|" \
    "$PACMAN_CONFIG"
}

configure_parallel_downloads() {
  local match_count

  match_count="$(
    grep -Ec \
      '^[#[:space:]]*ParallelDownloads[[:space:]]*=' \
      "$PACMAN_CONFIG" ||
      true
  )"

  if ((match_count == 0)); then
    die "ParallelDownloads is not present in the default pacman configuration."
  fi

  if ((match_count > 1)); then
    die "Multiple ParallelDownloads definitions were found."
  fi

  sed -Ei \
    "s|^[#[:space:]]*ParallelDownloads[[:space:]]*=.*$|ParallelDownloads = ${PARALLEL_DOWNLOADS}|" \
    "$PACMAN_CONFIG"
}

configure_pacman() {
  log "Enabling Color."
  enable_boolean_option "Color"

  log "Enabling VerbosePkgLists."
  enable_boolean_option "VerbosePkgLists"

  log "Enabling CheckSpace."
  enable_boolean_option "CheckSpace"

  log "Configuring parallel downloads."
  configure_parallel_downloads
}

validate_single_definition() {
  local pattern=$1
  local description=$2
  local count

  count="$(
    grep -Ec "$pattern" "$PACMAN_CONFIG" ||
      true
  )"

  ((count == 1)) ||
    die "Expected exactly one active ${description} definition, found: $count"
}

validate_options() {
  validate_single_definition \
    '^Color[[:space:]]*$' \
    "Color"

  validate_single_definition \
    '^VerbosePkgLists[[:space:]]*$' \
    "VerbosePkgLists"

  validate_single_definition \
    '^CheckSpace[[:space:]]*$' \
    "CheckSpace"

  validate_single_definition \
    "^ParallelDownloads[[:space:]]*=[[:space:]]*${PARALLEL_DOWNLOADS}[[:space:]]*$" \
    "ParallelDownloads"
}

validate_no_active_multilib() {
  if grep -Eq '^\[multilib\][[:space:]]*$' "$PACMAN_CONFIG"; then
    warn "The multilib repository is enabled."
    warn "This is outside the current minimal workstation profile."
  fi
}

validate_pacman_configuration() {
  log "Validating pacman configuration."

  pacman \
    --config "$PACMAN_CONFIG" \
    --sync \
    --print-format '%r/%n' \
    pacman >/dev/null
}

validate_repository_access() {
  log "Refreshing repository databases."

  pacman \
    --config "$PACMAN_CONFIG" \
    --sync \
    --refresh
}

show_result() {
  printf '\nPacman configured successfully.\n\n'

  printf 'Active managed options:\n\n'

  grep -E \
    '^(Color|VerbosePkgLists|CheckSpace|ParallelDownloads[[:space:]]*=)' \
    "$PACMAN_CONFIG" |
    sed 's/^/  /'

  printf '\nRepositories:\n\n'

  grep -E '^\[[^]]+\]$' "$PACMAN_CONFIG" |
    sed 's/^/  /'

  printf '\nNext step:\n'
  printf '  03-install-microcode\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  validate_execution_context
  validate_configuration_file
  show_plan
  confirm_configuration
  configure_pacman
  validate_options
  validate_no_active_multilib
  validate_pacman_configuration
  validate_repository_access
  show_result
}

main "$@"
```
