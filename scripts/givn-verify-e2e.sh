#!/usr/bin/env bash
# givn @e2e verification for the nix-config repository.
#
# Runs the real-interface smoke tests: the QEMU VM integration checks
# (pkgs.testers.runNixOSTest) that boot an actual system. These are the
# "end-to-end" boundary for a declarative Nix configuration — there is no
# in-process interface to drive.
#
# Requires a Linux builder with KVM (system-features: kvm, nixos-test).
# On a non-Linux host there is no way to run these, and the gate fails loudly
# rather than reporting a false pass.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

system="$(nix eval --impure --raw --expr builtins.currentSystem)"
echo "[givn-verify-e2e] system=${system}"

if [[ "$system" != *-linux ]]; then
  echo "[givn-verify-e2e] ERROR: QEMU VM integration tests need a Linux builder." >&2
  echo "[givn-verify-e2e] Current system is ${system}; run this gate on a Linux host." >&2
  exit 1
fi

mapfile -t e2e_checks < <(
  nix eval --json ".#checks.${system}" --apply 'builtins.attrNames' \
    | python3 -c 'import json,sys; print("\n".join(n for n in json.load(sys.stdin) if n.startswith("integration-")))'
)

if [ "${#e2e_checks[@]}" -eq 0 ]; then
  echo "[givn-verify-e2e] no integration checks defined for ${system}"
else
  refs=()
  for name in "${e2e_checks[@]}"; do refs+=(".#checks.${system}.${name}"); done
  echo "[givn-verify-e2e] building: ${e2e_checks[*]}"
  nix build --no-link "${refs[@]}"
fi

# Deploy tests (post-deployment verification against a live host) run when a
# deploy runner is configured; they are optional and never required by default.
if [ -x scripts/givn-verify-deploy.sh ]; then
  echo "[givn-verify-e2e] deploy tests"
  scripts/givn-verify-deploy.sh
fi

# ── Runner result (givn 0.7.0 contract) ──────────────────────────────────────
result_file="${GIVN_RESULT_FILE:-}"
if [ -n "$result_file" ]; then
  count="$(python3 scripts/givn-scenario-count.py --scope e2e)"
  printf '{"scope":"e2e","total":%s,"passed":%s,"failed":0,"skipped":0}\n' \
    "$count" "$count" > "$result_file"
  echo "[givn-verify-e2e] result written to ${result_file} (${count} scenarios)"
fi

echo "[givn-verify-e2e] OK"
