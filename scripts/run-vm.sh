#!/usr/bin/env bash
# Thin wrapper around the script produced by `system.build.vm` (qemu-vm.nix).
# That script handles disk image creation, EFI vars, and qemu invocation; we
# just need to find and exec it.
set -euo pipefail

runner=$(ls result/bin/run-*-vm 2>/dev/null | head -n1 || true)
if [ -z "$runner" ]; then
  echo "no VM runner under ./result/bin/ - run 'make vm' first" >&2
  exit 1
fi

exec "$runner" "$@"
