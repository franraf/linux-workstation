#!/usr/bin/env bash
set -Eeuo pipefail

SNAPPER_CONFIG="root"
MANUAL_LIMIT=5
MAINTENANCE_PAIR_LIMIT=10
APPLY=false

usage() {
  cat <<'EOF'
Usage:
  sudo bash retention.sh [--apply]

Default mode is dry-run. Only snapshots explicitly tagged with
class=manual or class=maintenance are considered. Untagged snapshots and
snapshot 0/current are never deletion candidates.
EOF
}

while (($# > 0)); do
  case "$1" in
    --apply) APPLY=true ;;
    --help|-h) usage; exit 0 ;;
    *) printf '[ERROR] Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

if [[ ${EUID} -ne 0 ]]; then
  printf '[ERROR] Run as root.\n' >&2
  exit 1
fi

command -v snapper >/dev/null || { printf '[ERROR] snapper is unavailable.\n' >&2; exit 1; }
snapper -c "$SNAPPER_CONFIG" get-config >/dev/null || { printf '[ERROR] Snapper config root is unavailable.\n' >&2; exit 1; }

mapfile -t snapshot_ids < <(find /.snapshots -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -E '^[0-9]+$' | sort -n)

manual_ids=()
maintenance_pre_ids=()
maintenance_post_by_pre=()

for id in "${snapshot_ids[@]}"; do
  [[ "$id" == "0" ]] && continue
  info="/.snapshots/${id}/info.xml"
  [[ -r "$info" ]] || continue

  userdata="$(sed -n 's:.*<userdata>\(.*\)</userdata>.*:\1:p' "$info" | head -n1)"
  type="$(sed -n 's:.*<type>\(.*\)</type>.*:\1:p' "$info" | head -n1)"
  pre="$(sed -n 's:.*<pre_num>\(.*\)</pre_num>.*:\1:p' "$info" | head -n1)"

  case "$userdata" in
    *class=manual*)
      [[ "$type" == "single" ]] && manual_ids+=("$id")
      ;;
    *class=maintenance*)
      if [[ "$type" == "pre" ]]; then
        maintenance_pre_ids+=("$id")
      elif [[ "$type" == "post" && "$pre" =~ ^[0-9]+$ ]]; then
        maintenance_post_by_pre+=("${pre}:${id}")
      fi
      ;;
  esac
done

candidate_groups=()

manual_excess=$((${#manual_ids[@]} - MANUAL_LIMIT))
if ((manual_excess > 0)); then
  for ((i=0; i<manual_excess; i++)); do
    candidate_groups+=("manual:${manual_ids[$i]}")
  done
fi

complete_pairs=()
for pre_id in "${maintenance_pre_ids[@]}"; do
  post_id=""
  for pair in "${maintenance_post_by_pre[@]}"; do
    if [[ "${pair%%:*}" == "$pre_id" ]]; then
      post_id="${pair##*:}"
      break
    fi
  done
  [[ -n "$post_id" ]] && complete_pairs+=("${pre_id}:${post_id}")
done

pair_excess=$((${#complete_pairs[@]} - MAINTENANCE_PAIR_LIMIT))
if ((pair_excess > 0)); then
  for ((i=0; i<pair_excess; i++)); do
    candidate_groups+=("maintenance:${complete_pairs[$i]}")
  done
fi

printf '\nSnapshot retention plan\n-----------------------\n'
printf 'Manual snapshots:       %d / %d\n' "${#manual_ids[@]}" "$MANUAL_LIMIT"
printf 'Maintenance pairs:      %d / %d\n' "${#complete_pairs[@]}" "$MAINTENANCE_PAIR_LIMIT"
printf 'Deletion candidate(s):  %d\n\n' "${#candidate_groups[@]}"

if ((${#candidate_groups[@]} == 0)); then
  printf '[PASS] Nothing is outside the approved retention limits.\n'
  exit 0
fi

for group in "${candidate_groups[@]}"; do
  printf '  %s\n' "$group"
done

if [[ "$APPLY" != true ]]; then
  printf '\n[DRY-RUN] No snapshots were deleted.\n'
  exit 0
fi

printf '\nType RETAIN to delete exactly the candidates above: '
read -r confirmation
[[ "$confirmation" == "RETAIN" ]] || { printf '[ERROR] Retention was not authorized.\n' >&2; exit 1; }

for group in "${candidate_groups[@]}"; do
  kind="${group%%:*}"
  ids="${group#*:}"
  if [[ "$kind" == "manual" ]]; then
    snapper -c "$SNAPPER_CONFIG" delete "$ids"
  else
    pre_id="${ids%%:*}"
    post_id="${ids##*:}"
    snapper -c "$SNAPPER_CONFIG" delete "$post_id" "$pre_id"
  fi
done

printf '\n[PASS] Approved retention candidates were deleted.\n'
