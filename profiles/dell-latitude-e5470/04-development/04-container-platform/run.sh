#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIRECTORY
REPO_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../../../.." && pwd)"
readonly REPO_ROOT
readonly PACKAGE_FILE="${REPO_ROOT}/packages/development/container-platform.txt"

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

Installs Docker Engine, Compose and Buildx from the official Arch Linux
repositories. Docker daemon access for the target user requires a separate
explicit confirmation because membership in the docker group is privileged.
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

user_has_docker_group() {
  local groups
  groups="$(id -nG "$TARGET_USER")"
  [[ " $groups " == *" docker "* ]]
}

show_plan() {
  printf '\nContainer platform setup\n------------------------\n\n'
  printf 'Target user:\n  %s\n\n' "$TARGET_USER"
  printf 'Package source:\n  %s\n\n' "$PACKAGE_FILE"
  printf 'Packages to install:\n'
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    printf '  none\n'
  else
    printf '  - %s\n' "${MISSING_PACKAGES[@]}"
  fi
}

confirm_installation() {
  local confirmation
  printf '\nType DOCKER to install/enable the container platform: '
  read -r confirmation
  [[ "$confirmation" == "DOCKER" ]] || die "Container platform setup was not authorized."
}

configure_service() {
  log_info "Enabling and starting docker.service."
  systemctl enable --now docker.service
  systemctl is-enabled --quiet docker.service || die "docker.service is not enabled."
  systemctl is-active --quiet docker.service || die "docker.service is not active."
}

grant_user_access() {
  if user_has_docker_group; then
    log_info "User ${TARGET_USER} is already a member of the docker group."
    return 0
  fi

  printf '\nMembership in the docker group grants privileged access to the Docker daemon.\n'
  printf 'Type DOCKER-GROUP to add %s to the docker group: ' "$TARGET_USER"
  local confirmation
  read -r confirmation
  [[ "$confirmation" == "DOCKER-GROUP" ]] || die "Docker group membership was not authorized."

  usermod -aG docker "$TARGET_USER"
  user_has_docker_group || die "User was not added to the docker group."
  log_warn "A new login session is required before ${TARGET_USER}'s existing shell and graphical session inherit docker group membership."
}

validate_platform() {
  docker version >/dev/null || die "Docker Engine validation failed."
  docker compose version >/dev/null || die "Docker Compose validation failed."
  docker buildx version >/dev/null || die "Docker Buildx validation failed."

  local data_root
  data_root="$(docker info --format '{{.DockerRootDir}}')"
  [[ "$data_root" == "/var/lib/docker" ]] || die "Unexpected Docker data root: $data_root"

  local filesystem_type
  filesystem_type="$(findmnt --noheadings --output FSTYPE --target /var/lib/docker 2>/dev/null | xargs)"
  [[ "$filesystem_type" == "btrfs" ]] || log_warn "/var/lib/docker is not currently backed by Btrfs: ${filesystem_type:-unknown}"

  printf '\nContainer platform configured successfully.\n\n'
  docker --version | sed 's/^/  /'
  docker compose version | sed 's/^/  /'
  docker buildx version | sed 's/^/  /'
  printf '\nThe full non-root and Dev Containers workflow will be validated after a fresh login session.\n'
  printf '\nNext step:\n  05-cli-tools\n'
}

main() {
  require_root
  require_commands awk findmnt id pacman sed systemctl usermod xargs
  require_arch_systemd
  require_user_config_commands
  parse_arguments "$@"
  resolve_normal_user "$TARGET_USER_ARG"

  load_package_file "$PACKAGE_FILE"
  validate_package_names
  validate_packages_available
  discover_missing_packages

  show_plan
  confirm_installation
  install_missing_packages
  validate_installed_packages
  require_commands docker
  configure_service
  grant_user_access
  validate_platform
}

main "$@"
