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

## HTTP Requests

- All HTTP requests MUST specify `timeout=(connect_s, read_s)`. Default: `timeout=(10, 30)`.
- Never call `requests.*` without `timeout=`.
- API clients MUST configure retry logic for transient failures (5xx, timeouts).
- Use `urllib3.util.retry.Retry` with `backoff_factor >= 1` and `status_forcelist=[500, 502, 503, 504]`.
- Never retry 4xx errors (except 429 with `Retry-After`).
- Maximum 3 retries.

## Error Handling

- `main()` MUST catch `KeyboardInterrupt` and exit with code 130.
- `main()` MUST catch unexpected `Exception` at the top level: log `str(exc)` to stderr and exit 1.
- In `--verbose` mode, re-raise to show the full traceback.
- Never show raw Python tracebacks to the user in normal mode.

### Main Guard Pattern

```python
def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv)
    # ... configure logging ...
    try:
        _DISPATCH[args.command](args)
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        sys.exit(130)
    except Exception as exc:  # noqa: BLE001
        if args.verbose:
            raise
        logger.error("%s", exc)
        sys.exit(1)
```

## Exit Code Semantics

- `0` — success
- `1` — runtime error
- `2` — argument/usage error (argparse default)
- `130` — `KeyboardInterrupt` (SIGINT)

## Destructive Operations

- Commands that mutate remote state MUST provide `--yes` to skip interactive confirmation.
- The `--yes` flag MUST be functionally checked in the command handler — adding the argparse argument without checking `args.yes` in the handler body is a rule violation.
- Every destructive command handler MUST contain a confirmation prompt gated on `if not args.yes:` before making changes.
- Tests MUST verify both paths: with `--yes` (proceeds) and without `--yes` (aborts on decline).
- Consider `--dry-run` to print planned actions without executing.

## Output Modes

- For tools that fetch or list data, provide `--output {text,json}`.
- In `json` mode: write a single JSON object to `stdout`, suppress all log output.
- Use flat structures with `lowercase_underscore` keys for `jq` compatibility.

## Environment Variable Fallback

- Frequently-repeated args MAY support env var fallback via `os.environ.get("TOOL_ARGNAME")` as the `argparse` default.
- Document env vars in `--help` output.
- Precedence: CLI arg > env var > built-in default.

## Help Text

- Use `epilog=` with `formatter_class=argparse.RawDescriptionHelpFormatter` to include working usage examples in `--help`.
