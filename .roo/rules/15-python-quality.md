# Python Code Quality — Type Hints, Linting, and Formatting

## Rule ID: PY-QUAL-001

**Priority**: MANDATORY  
**Applies to**: All Python files in `scripts/` and `tests/`

## Relationship to CODE-QUAL-001

This rule extends [`.roo/rules-code/03-code-quality.md`](../rules-code/03-code-quality.md) (CODE-QUAL-001) to cover `.py` files. The Nix quality gates (`deadnix`, `statix`, `nixfmt`) apply exclusively to `.nix` files. This rule defines quality gates for Python code.

## Type Hints

- Type hints are mandatory on all functions and methods.
- `mypy --strict` must pass without errors.
- Run from: `cd scripts && mypy --strict *.py`

## Linter

- Linter: `ruff check` with default rules plus `I` (isort), `UP` (pyupgrade), `S` (bandit/security).
- Zero violations allowed.
- Run from: `cd scripts && ruff check .`
- Configuration via `ruff.toml` or `[tool.ruff]` in `pyproject.toml` at `scripts/` level if needed.

## Formatter

- Formatter: `ruff format`.
- Code must be formatted before commit.
- Run from: `cd scripts && ruff format .`
- Check mode: `cd scripts && ruff format --check .`

## Tool Execution

- All tools run via Nix (`nix develop` shell). No global tool installations.
- Do not use `pip install ruff` or `pip install mypy`. Tools come from the devShell.

## Docstrings

- Module-level docstring required in every `.py` file.
- All public functions and methods require a docstring.
- Style: Google-style docstrings. Use consistently across the codebase.

## Verification Commands

| Command | Purpose |
|---------|---------|
| `cd scripts && mypy --strict *.py` | Type checking |
| `cd scripts && ruff check .` | Linting |
| `cd scripts && ruff format --check .` | Format verification |
| `cd scripts && ruff format .` | Auto-format |

## Quality Gate Checklist

Before completing any Python task:

- [ ] `mypy --strict` passes
- [ ] `ruff check` passes (zero violations)
- [ ] `ruff format --check` passes
- [ ] All public functions have Google-style docstrings
- [ ] Module-level docstring present
