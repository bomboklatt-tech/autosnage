#!/usr/bin/env bash
# Recover a flake source tree from the nix store. Restores files into cwd.
#
# How this works: when `nix build` evaluates a local flake, it copies the
# source tree to /nix/store/<hash>-source. That copy lives until GC, even if
# the original directory is deleted. We scan -source paths in the store for
# a flake.nix containing <marker> to identify the right project.
#
# A derivation's closure does NOT reference the flake source it came from
# (sources are eval-time inputs, not build-time deps), so we can't walk
# from a .drv. The marker (a substring of flake.nix) is what we match on.
#
# Usage:
#   scripts/recover-source.sh                # marker = cwd basename
#   scripts/recover-source.sh <marker>       # custom marker
#   scripts/recover-source.sh <-source-path> # restore a specific store path
set -euo pipefail

marker=${1:-$(basename "$PWD")}

stat_size() { stat -f %z "$1" 2>/dev/null || stat -c %s "$1"; }

restore() {
  local src=$1
  echo "recovering $src -> $PWD" >&2
  cp -R "$src/." .
  chmod -R u+w .
  echo "done." >&2
}

# Explicit store path? Skip the scan.
if [ -d "$marker" ] && [ -f "$marker/flake.nix" ]; then
  restore "$marker"
  exit 0
fi

echo "scanning /nix/store/*-source for flake.nix matching '$marker'..." >&2

matches=()
for d in /nix/store/*-source; do
  [ -f "$d/flake.nix" ] || continue
  grep -q "$marker" "$d/flake.nix" 2>/dev/null && matches+=("$d")
done

if [ ${#matches[@]} -eq 0 ]; then
  echo "no flake source matching '$marker' found in /nix/store" >&2
  echo "try a different marker (any substring guaranteed to be in your flake.nix)" >&2
  exit 1
fi

if [ ${#matches[@]} -eq 1 ]; then
  restore "${matches[0]}"
  exit 0
fi

echo "multiple candidates found:" >&2
for m in "${matches[@]}"; do
  sz=$(stat_size "$m/flake.nix")
  n=$(find "$m" \( -type f -o -type l \) 2>/dev/null | wc -l | tr -d ' ')
  dirty=""
  [ -L "$m/result" ] && dirty="$dirty result"
  find "$m" -maxdepth 1 -name '*.qcow2' -o -name '*.img' 2>/dev/null | grep -q . && dirty="$dirty image"
  printf "  %s  (flake.nix=%dB, files=%d%s)\n" "$m" "$sz" "$n" "${dirty:+, dirty:$dirty}" >&2
done

# Heuristic: prefer candidates with the largest flake.nix (most recent edit
# state), tiebreak by absence of build artifacts (result symlink, *.qcow2),
# then by file count.
best=$(for m in "${matches[@]}"; do
  sz=$(stat_size "$m/flake.nix")
  clean=1
  [ -L "$m/result" ] && clean=0
  find "$m" -maxdepth 1 -name '*.qcow2' -o -name '*.img' 2>/dev/null | grep -q . && clean=0
  n=$(find "$m" \( -type f -o -type l \) 2>/dev/null | wc -l | tr -d ' ')
  printf "%d\t%d\t%d\t%s\n" "$sz" "$clean" "$n" "$m"
done | sort -k1,1nr -k2,2nr -k3,3nr | head -1 | cut -f4-)

echo "picking $best. Override by passing the store path directly as the arg." >&2
restore "$best"
