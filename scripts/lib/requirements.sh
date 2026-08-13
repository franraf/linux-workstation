#!/usr/bin/env bash

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "This script must be executed as root."
}

require_commands() {
  (($# > 0)) || die "require_commands expects at least one command name."

  local command_name

  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      die "Required command not found: $command_name"
  done
}

require_arch_linux() {
  [[ -f /etc/os-release ]] ||
    die "The current root does not contain /etc/os-release."

  grep -q '^ID=arch$' /etc/os-release ||
    die "This script must run on Arch Linux."
}

require_systemd() {
  [[ -d /run/systemd/system ]] ||
    die "systemd is not running as PID 1."
}

require_arch_systemd() {
  require_arch_linux
  require_systemd
}

require_package_installed() {
  local package_name="${1:-}"
  local remediation="${2:-Install the required package before continuing.}"

  [[ -n "$package_name" ]] ||
    die "require_package_installed expects a package name."

  command -v pacman >/dev/null 2>&1 ||
    die "Required command not found: pacman"

  pacman -Q "$package_name" >/dev/null 2>&1 ||
    die "Required package is not installed: $package_name. $remediation"
}
