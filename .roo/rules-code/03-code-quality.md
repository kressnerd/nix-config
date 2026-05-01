# Nix Code Quality

## Rule ID: CODE-QUAL-001

**Priority**: MANDATORY
**Applies to**: All `.nix` file changes in Code Mode

## Linting

After completing a change, run linting tools on modified files:

### Tools (in order)

| Tool | Command | Purpose |
|------|---------|---------|
| deadnix | `deadnix <file>` | Find unused variables and expressions in one or more files |
| statix | `statix check <file>` | Find anti-patterns and suggest fixes in exactly one file|

#### statix W20 — Repeated Attribute Path Prefixes

Do NOT write repeated dotted paths at the same indentation level:

```nix
# BAD — triggers statix W20
gaps.inner.horizontal = 4;
gaps.inner.vertical = 4;
```

Write nested attrsets instead:

```nix
# GOOD
gaps.inner = {
  horizontal = 4;
  vertical = 4;
};
```

### Auto-fix

- `statix fix <file>` — apply safe automatic fixes to one file
- `deadnix -e <file>` — remove unused bindings (use with caution)

Auto-fix is allowed when the fix is obvious. If uncertain, report the finding and let the caller decide.

### Formatting

| Tool | Command | Purpose |
|------|---------|---------|
| nixfmt | `nixfmt <file>` or `nix fmt .` | Official Nix formatter (RFC 166) |

## Quality Checklist

Before reporting task completion, verify:

- [ ] No `deadnix` warnings on changed files
- [ ] No `statix` warnings on changed files
- [ ] Changed files are formatted
- [ ] No broad `with pkgs;` scoping (use explicit attribute access or limited `with` scope)
- [ ] No hardcoded secrets in `.nix` files
- [ ] Module function signatures follow convention: destructure with `...` when arguments are used; `_:` when no arguments are used

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

## Python Code Quality

For `.py` files in `scripts/`, see PY-QUAL-001 in [`.roo/rules/15-python-quality.md`](../rules/15-python-quality.md).

Python quality gates: `mypy --strict`, `ruff check`, `ruff format`. These replace the Nix tools (`deadnix`, `statix`, `nixfmt`) for Python files.
