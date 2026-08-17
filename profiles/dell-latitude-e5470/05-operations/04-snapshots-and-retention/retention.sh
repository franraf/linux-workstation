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
command -v jq >/dev/null || { printf '[ERROR] jq is unavailable.\n' >&2; exit 1; }
snapper -c "$SNAPPER_CONFIG" get-config >/dev/null || { printf '[ERROR] Snapper config root is unavailable.\n' >&2; exit 1; }

snapshot_json="$(snapper --jsonout -c "$SNAPPER_CONFIG" list --columns number,userdata,pre-number,post-number)"

mapfile -t manual_ids < <(
  jq -r --arg config "$SNAPPER_CONFIG" '
    .[$config][]
    | select(.number != 0)
    | select(.userdata.class? == "manual")
    | select(."pre-number" == null and ."post-number" == null)
    | .number
  ' <<<"$snapshot_json" | sort -n
)

mapfile -t maintenance_pairs < <(
  jq -r --arg config "$SNAPPER_CONFIG" '
    .[$config] as $items
    | $items[]
    | select(.number != 0)
    | select(.userdata.class? == "maintenance")
    | select(."post-number" != null)
    | . as $pre
    | ($items[] | select(.number == $pre."post-number")) as $post
    | select($post.userdata.class? == "maintenance")
    | select($post."pre-number" == $pre.number)
    | "\($pre.number):\($post.number)"
  ' <<<"$snapshot_json" | sort -t: -k1,1n
)

candidate_groups=()

manual_excess=$((${#manual_ids[@]} - MANUAL_LIMIT))
if ((manual_excess > 0)); then
  for ((i=0; i<manual_excess; i++)); do
    candidate_groups+=("manual:${manual_ids[$i]}")
  done
fi

pair_excess=$((${#maintenance_pairs[@]} - MAINTENANCE_PAIR_LIMIT))
if ((pair_excess > 0)); then
  for ((i=0; i<pair_excess; i++)); do
    candidate_groups+=("maintenance:${maintenance_pairs[$i]}")
  done
fi

printf '\nSnapshot retention plan\n-----------------------\n'
printf 'Manual snapshots:       %d / %d\n' "${#manual_ids[@]}" "$MANUAL_LIMIT"
printf 'Maintenance pairs:      %d / %d\n' "${#maintenance_pairs[@]}" "$MAINTENANCE_PAIR_LIMIT"
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
