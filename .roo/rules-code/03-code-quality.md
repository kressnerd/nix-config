# Nix Code Quality

## Rule ID: CODE-QUAL-001

**Priority**: MANDATORY
**Applies to**: All `.nix` file changes in Code Mode

## Linting

After completing a change, run linting tools on modified files:

### Tools (in order)

| Tool | Command | Purpose |
|------|---------|---------|
| deadnix | `deadnix <file>` | Find unused variables and expressions |
| statix | `statix check <file>` | Find anti-patterns and suggest fixes |

### Auto-fix

- `statix fix <file>` — apply safe automatic fixes
- `deadnix -e <file>` — remove unused bindings (use with caution)

Auto-fix is allowed when the fix is obvious. If uncertain, report the finding and let the caller decide.

### Formatting

| Tool | Command | Purpose |
|------|---------|---------|
| nixfmt | `nixfmt <file>` | Official Nix formatter |
| alejandra | `alejandra <file>` | Alternative formatter |

Use whichever formatter is configured in the project's devShell (this repo provides both).

## Quality Checklist

Before reporting task completion, verify:

- [ ] No `deadnix` warnings on changed files
- [ ] No `statix` warnings on changed files
- [ ] Changed files are formatted
- [ ] No broad `with pkgs;` scoping (use explicit attribute access or limited `with` scope)
- [ ] No hardcoded secrets in `.nix` files
- [ ] Module function signatures include `...` for forward compatibility

## Return Format

Include quality results in the DONE response:

```
QUALITY:
- deadnix: PASS/FAIL (N warnings)
- statix: PASS/FAIL (N warnings)
- format: PASS/FAIL
```

## Enforcement

- Lint failures block task completion unless explicitly overridden by the caller
- If auto-fix changes semantics, report as BLOCKED with details
