#!/usr/bin/env bash
# Report total closure size of a flake target and its 20 fattest paths.
# Substitutes from the binary cache when possible; will trigger builds for
# anything the cache doesn't have.
#
# Usage:
#   scripts/closure-report.sh                # default: rockpro64 toplevel
#   scripts/closure-report.sh .#nixosConfigurations.rpi5.config.system.build.toplevel
#   scripts/closure-report.sh .#vm
#
# Default is rockpro64: it uses a stock kernel (cached), so the build is much
# faster than rpi5 which rebuilds the rpi-rpt1 kernel from source.
#
# To compare before/after a change:
#   git stash; scripts/closure-report.sh > /tmp/before
#   git stash pop; scripts/closure-report.sh > /tmp/after
#   diff -u /tmp/before /tmp/after
set -euo pipefail

target=${1:-.#nixosConfigurations.rockpro64.config.system.build.toplevel}

# The .#rpi5 / .#vm packages are derivations of the image, not the toplevel.
# For closure-size analysis we usually want the toplevel (system path).
# Allow either - eval to find out which we got.
echo "evaluating $target..." >&2

drv=$(nix eval --raw "$target.drvPath" 2>/dev/null || true)
if [ -z "$drv" ]; then
  echo "could not resolve $target - try .#nixosConfigurations.<name>.config.system.build.toplevel" >&2
  exit 1
fi

echo "realising store path (may substitute or build)..." >&2
out=$(nix build --no-link --print-out-paths "$target")

# narSize column only; -S shows transitive closure summed
total_bytes=$(nix path-info --json -S "$out" | nix run nixpkgs#jq -- -r '.[0].closureSize')
total_mb=$(( total_bytes / 1024 / 1024 ))

echo
echo "=== $target ==="
echo "closure size: ${total_mb} MB  (${total_bytes} bytes)"
echo "store path:   $out"
echo
echo "--- top 20 paths by SELF size (each path's own bytes) ---"
nix path-info -rsh "$out" 2>/dev/null \
  | sort -h -k2 \
  | tail -20
echo
echo "--- top 20 paths by CLOSURE size (path + everything it pulls in) ---"
echo "high closure size = good target for override/replacement"
nix path-info -rSh "$out" 2>/dev/null \
  | sort -h -k2 \
  | tail -20
