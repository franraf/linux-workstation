#!/usr/bin/env bash

load_package_file() {
  local package_file="$1"

  [[ -f "$package_file" ]] || die "Package file does not exist: $package_file"
  [[ -r "$package_file" ]] || die "Package file is not readable: $package_file"

  mapfile -t PACKAGES < <(
    awk '
      {
        sub(/[[:space:]]*#.*/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      }
      length($0) > 0 { print }
    ' "$package_file"
  )

  ((${#PACKAGES[@]} > 0)) || die "Package file does not contain packages: $package_file"
}

validate_package_names() {
  local package
  for package in "${PACKAGES[@]}"; do
    [[ "$package" =~ ^[a-zA-Z0-9@._+-]+$ ]] || die "Invalid package name: $package"
  done
}

validate_packages_available() {
  local package
  for package in "${PACKAGES[@]}"; do
    pacman -Si "$package" >/dev/null 2>&1 || die "Package unavailable from configured repositories: $package"
  done
}

discover_missing_packages() {
  MISSING_PACKAGES=()
  local package
  for package in "${PACKAGES[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 || MISSING_PACKAGES+=("$package")
  done
}

install_missing_packages() {
  if ((${#MISSING_PACKAGES[@]} == 0)); then
    log_info "All declared packages are already installed."
    return
  fi

  pacman -S --needed "${MISSING_PACKAGES[@]}"
}

validate_installed_packages() {
  local package
  for package in "${PACKAGES[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 || die "Package was not installed successfully: $package"
  done
}
