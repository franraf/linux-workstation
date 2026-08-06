#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_TARGET_ROOT="/mnt"

readonly EXPECTED_MOUNTPOINTS=(
  "/"
  "/boot"
  "/home"
  "/var"
  "/var/log"
  "/var/cache"
  "/var/cache/pacman/pkg"
  "/var/lib/docker"
  "/.snapshots"
)

TARGET_ROOT="$DEFAULT_TARGET_ROOT"
FSTAB_PATH=""

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
  sudo ./$SCRIPT_NAME [options]

Options:
  --root <path>
      Mounted target root.
      Default: ${DEFAULT_TARGET_ROOT}

  --help, -h
      Show this help message.

Examples:
  sudo ./$SCRIPT_NAME

  sudo ./$SCRIPT_NAME --root /mnt

This script generates:

  <target-root>/etc/fstab

The generated entries use filesystem UUIDs.
EOF
}

require_root() {
  [[ $EUID -eq 0 ]] ||
    die "This script must be executed as root."
}

require_commands() {
  local commands=(
    awk
    findmnt
    genfstab
    grep
    install
    mktemp
    mount
    readlink
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
      --root)
        (($# >= 2)) ||
          die "Missing value for --root."

        TARGET_ROOT="$2"
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

canonicalize_paths() {
  [[ -e "$TARGET_ROOT" ]] ||
    die "Target root does not exist: $TARGET_ROOT"

  TARGET_ROOT="$(readlink -f "$TARGET_ROOT")"
  FSTAB_PATH="${TARGET_ROOT}/etc/fstab"
}

validate_target_root() {
  [[ -d "$TARGET_ROOT" ]] ||
    die "Target root is not a directory: $TARGET_ROOT"

  [[ "$TARGET_ROOT" != "/" ]] ||
    die "Refusing to operate on the running root filesystem."

  findmnt --mountpoint "$TARGET_ROOT" >/dev/null 2>&1 ||
    die "Target root is not a mountpoint: $TARGET_ROOT"

  local filesystem_type
  local filesystem_root

  filesystem_type="$(
    findmnt \
      --noheadings \
      --output FSTYPE \
      --target "$TARGET_ROOT" |
      xargs
  )"

  filesystem_root="$(
    findmnt \
      --noheadings \
      --output FSROOT \
      --target "$TARGET_ROOT" |
      xargs
  )"

  [[ "$filesystem_type" == "btrfs" ]] ||
    die "Expected Btrfs at $TARGET_ROOT."

  [[ "$filesystem_root" == "/@" ]] ||
    die "Expected the @ subvolume at $TARGET_ROOT."
}

validate_installed_system() {
  [[ -d "$TARGET_ROOT/etc" ]] ||
    die "Target system does not contain /etc."

  [[ -f "$TARGET_ROOT/etc/os-release" ]] ||
    die "Target system does not contain /etc/os-release."

  grep -q '^ID=arch$' "$TARGET_ROOT/etc/os-release" ||
    die "Target system is not identified as Arch Linux."
}

validate_mount_tree() {
  local relative_mountpoint
  local absolute_mountpoint

  for relative_mountpoint in "${EXPECTED_MOUNTPOINTS[@]}"; do
    if [[ "$relative_mountpoint" == "/" ]]; then
      absolute_mountpoint="$TARGET_ROOT"
    else
      absolute_mountpoint="${TARGET_ROOT}${relative_mountpoint}"
    fi

    findmnt --mountpoint "$absolute_mountpoint" >/dev/null 2>&1 ||
      die "Required mountpoint is missing: $absolute_mountpoint"
  done
}

validate_mount_sources() {
  local root_source
  local root_device
  local mountpoint
  local absolute_mountpoint
  local source
  local source_device

  root_source="$(
    findmnt \
      --noheadings \
      --output SOURCE \
      --target "$TARGET_ROOT" |
      xargs
  )"

  root_device="${root_source%%\[*}"

  [[ -b "$root_device" ]] ||
    die "Unable to determine the root block device: $root_device"

  for mountpoint in \
    "/home" \
    "/var" \
    "/var/log" \
    "/var/cache" \
    "/var/cache/pacman/pkg" \
    "/var/lib/docker" \
    "/.snapshots"; do

    absolute_mountpoint="${TARGET_ROOT}${mountpoint}"

    source="$(
      findmnt \
        --noheadings \
        --output SOURCE \
        --target "$absolute_mountpoint" |
        xargs
    )"

    source_device="${source%%\[*}"

    [[ "$source_device" == "$root_device" ]] ||
      die "Unexpected source mounted at $absolute_mountpoint."
  done
}

validate_existing_fstab() {
  if [[ -e "$FSTAB_PATH" ]]; then
    if [[ -s "$FSTAB_PATH" ]]; then
      die "A non-empty fstab already exists: $FSTAB_PATH"
    fi

    warn "An empty fstab already exists and will be replaced."
  fi
}

show_plan() {
  cat <<EOF

Target system
-------------

Root:  $TARGET_ROOT
fstab: $FSTAB_PATH

Expected mountpoints
--------------------

EOF

  printf '  - %s\n' "${EXPECTED_MOUNTPOINTS[@]}"

  cat <<EOF

Generation policy
-----------------

Source identifiers: UUID
Existing file:      must not contain entries
EOF
}

confirm_generation() {
  local confirmation

  printf '\nType GENERATE to create the target fstab: '
  read -r confirmation

  [[ "$confirmation" == "GENERATE" ]] ||
    die "fstab generation was not authorized."
}

generate_fstab() {
  local temporary_file

  temporary_file="$(mktemp)"

  trap 'rm -f "$temporary_file"' RETURN

  log "Generating fstab using filesystem UUIDs."

  genfstab \
    -U \
    "$TARGET_ROOT" \
    >"$temporary_file"

  [[ -s "$temporary_file" ]] ||
    die "genfstab produced an empty file."

  install \
    --mode 0644 \
    "$temporary_file" \
    "$FSTAB_PATH"

  rm -f "$temporary_file"
  trap - RETURN
}

get_fstab_mountpoints() {
  awk '
    /^[[:space:]]*#/ {
      next
    }

    NF >= 2 {
      print $2
    }
  ' "$FSTAB_PATH"
}

validate_expected_mountpoint() {
  local expected_mountpoint=$1
  local actual_mountpoints=$2

  grep -Fxq "$expected_mountpoint" <<<"$actual_mountpoints" ||
    die "Expected fstab mountpoint is missing: $expected_mountpoint"
}

validate_no_duplicate_mountpoints() {
  local duplicates

  duplicates="$(
    get_fstab_mountpoints |
      sort |
      uniq -d
  )"

  [[ -z "$duplicates" ]] ||
    die "Duplicate mountpoints found in fstab: $duplicates"
}

validate_uuid_sources() {
  local invalid_sources

  invalid_sources="$(
    awk '
      /^[[:space:]]*#/ {
        next
      }

      NF >= 2 && $1 !~ /^UUID=/ {
        print $1
      }
    ' "$FSTAB_PATH"
  )"

  [[ -z "$invalid_sources" ]] ||
    die "Non-UUID sources found in fstab: $invalid_sources"
}

validate_fstab_entries() {
  local actual_mountpoints
  local expected_mountpoint
  local actual_count
  local expected_count="${#EXPECTED_MOUNTPOINTS[@]}"

  actual_mountpoints="$(get_fstab_mountpoints)"

  for expected_mountpoint in "${EXPECTED_MOUNTPOINTS[@]}"; do
    validate_expected_mountpoint \
      "$expected_mountpoint" \
      "$actual_mountpoints"
  done

  actual_count="$(
    printf '%s\n' "$actual_mountpoints" |
      sed '/^[[:space:]]*$/d' |
      wc -l
  )"

  ((actual_count == expected_count)) ||
    die "Expected $expected_count fstab entries, found $actual_count."

  validate_no_duplicate_mountpoints
  validate_uuid_sources
}

validate_btrfs_entries() {
  local mountpoint

  for mountpoint in \
    "/" \
    "/home" \
    "/var" \
    "/var/log" \
    "/var/cache" \
    "/var/cache/pacman/pkg" \
    "/var/lib/docker" \
    "/.snapshots"; do

    awk -v target="$mountpoint" '
      /^[[:space:]]*#/ {
        next
      }

      $2 == target {
        if ($3 != "btrfs") {
          exit 1
        }

        if ($4 !~ /(^|,)noatime(,|$)/) {
          exit 2
        }

        if ($4 !~ /(^|,)compress=zstd:3(,|$)/) {
          exit 3
        }

        found = 1
      }

      END {
        if (!found) {
          exit 4
        }
      }
    ' "$FSTAB_PATH" ||
      die "Invalid Btrfs entry for mountpoint: $mountpoint"
  done
}

validate_subvolume_entries() {
  local expected_entries=(
    "/:subvol=/@"
    "/home:subvol=/@home"
    "/var:subvol=/@var"
    "/var/log:subvol=/@var_log"
    "/var/cache:subvol=/@var_cache"
    "/var/cache/pacman/pkg:subvol=/@pkg"
    "/var/lib/docker:subvol=/@docker"
    "/.snapshots:subvol=/@snapshots"
  )

  local mapping
  local mountpoint
  local expected_option

  for mapping in "${expected_entries[@]}"; do
    mountpoint="${mapping%%:*}"
    expected_option="${mapping#*:}"

    awk \
      -v target="$mountpoint" \
      -v expected="$expected_option" '
        /^[[:space:]]*#/ {
          next
        }

        $2 == target {
	  options = "," $4 ","
	  expected_value = "," expected ","

	  if (index(options,expected_value) == 0) {
            exit 1
          }

          found = 1
        }

        END {
          if (!found) {
            exit 2
          }
        }
      ' "$FSTAB_PATH" ||
      die "Expected option $expected_option is missing for $mountpoint."
  done
}

validate_efi_entry() {
  awk '
    /^[[:space:]]*#/ {
      next
    }

    $2 == "/boot" {
      if ($3 != "vfat") {
        exit 1
      }

      found = 1
    }

    END {
      if (!found) {
        exit 2
      }
    }
  ' "$FSTAB_PATH" ||
    die "Invalid EFI System Partition entry."
}

validate_mount_simulation() {
  log "Validating fstab syntax using mount."

  mount \
    --fake \
    --all \
    --fstab "$FSTAB_PATH"
}

show_result() {
  printf '\nfstab generated successfully.\n\n'

  cat "$FSTAB_PATH"

  printf '\nValidated mountpoints:\n\n'
  printf '  ✓ %s\n' "${EXPECTED_MOUNTPOINTS[@]}"

  printf '\nNext step:\n'
  printf '  11-enter-chroot\n'
}

main() {
  require_root
  require_commands
  parse_arguments "$@"

  canonicalize_paths
  validate_target_root
  validate_installed_system
  validate_mount_tree
  validate_mount_sources
  validate_existing_fstab
  show_plan
  confirm_generation
  generate_fstab
  validate_fstab_entries
  validate_btrfs_entries
  validate_subvolume_entries
  validate_efi_entry
  validate_mount_simulation
  show_result
}

main "$@"
