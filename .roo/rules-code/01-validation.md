# Validation After Changes

## Rule ID: CODE-VALID-001

**Priority**: MANDATORY
**Applies to**: All code changes in Code Mode

## Rule

Every task is only complete when the changed configuration has been validated.

### Validation Steps (in order)

1. **Syntax check**: `nix flake check` must pass without errors
2. **Build test** (if a specific host was modified): `nixos-rebuild build --flake .#<hostname>` or `darwin-rebuild build --flake .#<hostname>`
3. **Format check**: Run `nixfmt` or `alejandra` on changed `.nix` files — no formatting errors

### When to Skip

- Documentation-only changes (`.md` files) do not require `nix flake check`
- Changes to `scripts/` shell scripts do not require Nix validation

### Return Format

Include validation results in the DONE response:

```
VALIDATION:
- flake check: PASS/FAIL
- build (<hostname>): PASS/FAIL/SKIPPED
- format: PASS/FAIL
```

## Enforcement

- Task completion without validation = rule violation
- If `nix flake check` fails, the task is BLOCKED until fixed
