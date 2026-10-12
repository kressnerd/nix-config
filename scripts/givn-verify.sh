#!/usr/bin/env bash
# givn non-e2e verification for the nix-config repository.
#
# Runs the evaluation-level verification of the whole repository:
#   1. spec traceability (every scenario bound to a real check/host)
#   2. evaluation of every flake output and check for the current system
#   3. build of the non-VM checks (unit tests and linters)
#   4. evaluation of every host configuration (fires tests/assertions)
#   5. the Python test suite for the repository scripts
#
# This is the givn `verify.command`. It does NOT run the QEMU VM integration
# tests — those are the @e2e scope (scripts/givn-verify-e2e.sh).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

system="$(nix eval --impure --raw --expr builtins.currentSystem)"
echo "[givn-verify] system=${system}"

echo "[givn-verify] 1/5 spec traceability"
python3 scripts/givn-spec-trace.py

echo "[givn-verify] 2/5 flake evaluation (all outputs, current system)"
nix flake check --no-build --no-write-lock-file

echo "[givn-verify] 3/5 build non-VM checks (unit + lint)"
mapfile -t build_checks < <(
  nix eval --json ".#checks.${system}" --apply 'builtins.attrNames' \
    | python3 -c 'import json,sys; print("\n".join(n for n in json.load(sys.stdin) if not n.startswith("integration-")))'
)
if [ "${#build_checks[@]}" -gt 0 ]; then
  refs=()
  for name in "${build_checks[@]}"; do refs+=(".#checks.${system}.${name}"); done
  nix build --no-link "${refs[@]}"
else
  echo "[givn-verify] no non-VM checks defined"
fi

echo "[givn-verify] 4/5 host configuration assertions (tests/assertions)"
# Force each host's `config.assertions` and fail on the first false one. This
# fires the tests/assertions invariants without forcing the full toplevel
# derivation; buildability of a touched host is proven per scenario by the
# targeted `@host:<name>` command (docs/GIVN-VERIFICATION.md).
assert_configs() {
  local output="$1" kind="$2" host failed
  local hosts
  hosts="$(nix eval --json ".#${output}" --apply 'builtins.attrNames' 2>/dev/null || echo '[]')"
  for host in $(python3 -c 'import json,sys; print("\n".join(json.load(sys.stdin)))' <<<"$hosts"); do
    echo "[givn-verify]   ${kind}.${host}"
    failed="$(nix eval --raw ".#${output}.${host}.config.assertions" --apply \
      'as: builtins.concatStringsSep "\n  - " (map (a: a.message) (builtins.filter (a: !a.assertion) as))')"
    if [ -n "$failed" ]; then
      printf '[givn-verify]   FAILED assertions in %s:\n  - %s\n' "$host" "$failed" >&2
      return 1
    fi
  done
}
assert_configs nixosConfigurations nixosConfiguration
assert_configs darwinConfigurations darwinConfiguration

echo "[givn-verify] 5/5 python test suite (scripts/)"
if [ -d scripts/tests ]; then
  nix develop --command python3 -m pytest scripts/tests -q
else
  echo "[givn-verify] no scripts/tests directory"
fi

# ── Runner result (givn 0.7.0 contract) ──────────────────────────────────────
# Each scope writes real scenario counts to $GIVN_RESULT_FILE when givn asks for
# them; a developer running the script directly sees the previous behaviour.
result_file="${GIVN_RESULT_FILE:-}"
if [ -n "$result_file" ]; then
  count="$(python3 scripts/givn-scenario-count.py --scope regular)"
  printf '{"scope":"regular","total":%s,"passed":%s,"failed":0,"skipped":0}\n' \
    "$count" "$count" > "$result_file"
  echo "[givn-verify] result written to ${result_file} (${count} scenarios)"
fi

echo "[givn-verify] OK"
