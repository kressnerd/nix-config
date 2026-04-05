# Validation After Changes

## Rule ID: CODE-VALID-001

**Priority**: MANDATORY
**Applies to**: All code changes in Code Mode

## Rule

Every task is only complete when the changed configuration has been validated.

### Validation Steps (in order)

1. **Syntax check**: `nix flake check` must pass without errors
2. **Build test** (if a specific host was modified): `nixos-rebuild build --flake .#<hostname>` or `darwin-rebuild build --flake .#<hostname>`
3. **Format check**: Run `nixfmt` on changed `.nix` files — no formatting errors
4. **Test run** (if tests exist for the changed module): `nix build .#checks.<system>.<test-name>` or `nix flake check` to run all checks

### When to Skip

- Documentation-only changes (`.md` files) do not require `nix flake check`
- Changes to `scripts/` shell scripts do not require Nix validation
- Test step may be skipped if no tests exist for the changed area (report as SKIPPED)

### Return Format

Include validation results in the DONE response:

```
VALIDATION:
- flake check: PASS/FAIL
- build (<hostname>): PASS/FAIL/SKIPPED
- format: PASS/FAIL
- tests: PASS/FAIL/SKIPPED (N unit, M integration)
```

## Enforcement

- Task completion without validation = rule violation
- If `nix flake check` fails, the task is BLOCKED until fixed
- If tests exist for the changed area and they fail, the task is BLOCKED until fixed
