# Python CLI Standards — Conventions for all Python CLI tools in `scripts/`

## Rule ID: PY-CLI-001

**Priority**: MANDATORY  
**Applies to**: All Python CLI tools in `scripts/`

## Relationship to Existing Rules

This rule extends [`.roo/rules/14-python-tdd.md`](14-python-tdd.md) (PY-TDD-001), [`.roo/rules/15-python-quality.md`](15-python-quality.md) (PY-QUAL-001), and [`.roo/rules/16-python-nix-integration.md`](16-python-nix-integration.md) (PY-NIX-001) with CLI-specific conventions.

## CLI Framework

- Use `argparse` (stdlib) as the CLI framework.
- All existing tools use `argparse`. Maintain consistency.
- Use the `parse_args(argv=None)` pattern — accept an injectable `argv` parameter for testability.

## Exit Codes

- Exit code `0` on success.
- Exit code `≠ 0` on failure — use `sys.exit(1)` or raise `SystemExit`.
- Never silently swallow errors.

## Output Conventions

- Error output to `stderr` (`print(..., file=sys.stderr)`).
- Useful output (data, results) to `stdout`.
- Provide `--help` for every command and subcommand.

## No Global State

- Functions are pure where possible.
- Side effects (I/O, API calls, file writes) isolated into injectable dependencies.
- Use the dependency injection pattern: `cmd_<action>(args, auth=None, client=None)`.
- No module-level mutable state.

## Logging

- Use the `logging` module, not `print()`, for diagnostic output.
- Verbosity controllable via `--verbose` / `--quiet` flags.
- Default log level: `WARNING`.
- `--verbose`: set to `INFO` or `DEBUG`.
- `--quiet`: suppress all output below `ERROR`.

## Argument Parsing Pattern

```python
def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Tool description")
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--quiet", action="store_true")
    subparsers = parser.add_subparsers(dest="command", required=True)
    # ... add subcommands
    return parser.parse_args(argv)
```

## Command Handler Pattern

```python
def cmd_action(
    args: argparse.Namespace,
    auth: AuthClient | None = None,
    client: ApiClient | None = None,
) -> None:
    if auth is None:
        auth = AuthClient()
    if client is None:
        client = ApiClient(auth)
    # ... implementation
```

## Main Guard

- Every CLI script includes an `if __name__ == "__main__":` guard.
- The guard calls `parse_args()` and dispatches to the appropriate command handler.

## Security

- No hardcoded credentials in source.
- Credential files stored at `~/.config/<tool>/` with `0o600` permissions.
- Credential directories created with `0o700` permissions.
