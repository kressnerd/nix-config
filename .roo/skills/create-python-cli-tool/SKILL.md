# Skill: Create Python CLI Tool

**Summary**: Step-by-step procedure for creating a new Python CLI tool in `scripts/`.  
**Trigger**: When creating a new Python CLI tool.  
**Rules**: PY-TDD-001, PY-QUAL-001, PY-NIX-001, PY-CLI-001

---

## Step 1: Write Failing Test (Red)

Create the test file first — before any implementation exists.

**File**: `scripts/tests/test_<tool_name>.py`

Minimum coverage required:
- Argument parsing (`parse_args`)
- `--help` exits with code `0`
- At least one business logic test (mock external calls)

Run the test and confirm it **fails**:

```bash
cd scripts && python3 -m pytest tests/test_<tool_name>.py -v
```

Expected result: `FAILED` or `ImportError`. Do not proceed until failure is confirmed.

---

## Step 2: Write Minimal Implementation (Green)

Create the implementation file with the minimum code to pass the failing test.

**File**: `scripts/<tool_name>.py`

Required patterns (PY-CLI-001):
- `parse_args(argv: list[str] | None = None)` — injectable `argv`
- `cmd_<action>(args, auth=None, client=None)` — injectable dependencies
- `if __name__ == "__main__":` guard

Run the test and confirm it **passes**:

```bash
cd scripts && python3 -m pytest tests/test_<tool_name>.py -v
```

Expected result: `PASSED`. Do not proceed until all targeted tests pass.

---

## Step 3: Quality Gates

Run all quality tools on the new files:

```bash
cd scripts && mypy --strict <tool_name>.py
cd scripts && ruff check .
cd scripts && ruff format .
```

All must pass with zero errors. Fix any issues before continuing.

---

## Step 4: Iterate (Red-Green-Refactor)

For each additional feature or subcommand:

1. **Red** — Write a failing test for the new behavior
2. **Green** — Implement the minimum code to pass it
3. **Refactor** — Clean up while keeping all tests green

One feature per Red-Green cycle. Do not batch multiple behaviors.

Verify after each refactor:

```bash
cd scripts && python3 -m pytest tests/ -v
```

---

## Step 5: Nix Package Definition

Add any new Python dependencies to the `devShell` in `flake.nix` if not already present (PY-NIX-001). No `pip install`, no `requirements.txt`.

Optionally package the script as a Nix derivation in `pkgs/` using `writeShellApplication` or `buildPythonApplication`.

Verify the flake is still valid:

```bash
nix flake check
```

---

## Step 6: Final Verification

Run the full test suite and all quality gates:

```bash
cd scripts && python3 -m pytest tests/ -v
cd scripts && mypy --strict <tool_name>.py
cd scripts && ruff check .
cd scripts && ruff format --check .
nix flake check
```

All must pass before the task is complete.

---

## Template: Test File

`scripts/tests/test_<tool_name>.py`

```python
"""Tests for <tool_name> CLI tool."""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import <tool_name>


class TestArgParsing:
    """Test argument parsing."""

    def test_help_exits_zero(self) -> None:
        with pytest.raises(SystemExit) as exc_info:
            <tool_name>.parse_args(["--help"])
        assert exc_info.value.code == 0

    def test_missing_command_exits_nonzero(self) -> None:
        with pytest.raises(SystemExit) as exc_info:
            <tool_name>.parse_args([])
        assert exc_info.value.code != 0

    def test_parse_example_command(self) -> None:
        args = <tool_name>.parse_args(["example", "--server", "test"])
        assert args.command == "example"
        assert args.server == "test"


class TestExampleCommand:
    """Test example command business logic."""

    def test_example_calls_api(self) -> None:
        mock_client = MagicMock()
        mock_auth = MagicMock()
        args = <tool_name>.parse_args(["example", "--server", "test"])
        <tool_name>.cmd_example(args, auth=mock_auth, client=mock_client)
        mock_client.some_method.assert_called_once()
```

---

## Template: Script File

`scripts/<tool_name>.py`

```python
"""<Tool description>."""

from __future__ import annotations

import argparse
import logging
import sys
from collections.abc import Callable

logger = logging.getLogger(__name__)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="<Tool description>")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    parser.add_argument("--quiet", action="store_true", help="Suppress non-error output")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Example subcommand
    example_parser = subparsers.add_parser("example", help="Example command")
    example_parser.add_argument("--server", required=True, help="Target server name")

    return parser.parse_args(argv)


def cmd_example(
    args: argparse.Namespace,
    auth: object | None = None,
    client: object | None = None,
) -> None:
    """Execute example command."""
    # Implementation here
    pass


_DISPATCH: dict[str, Callable[[argparse.Namespace], None]] = {
    "example": cmd_example,
}


def main(argv: list[str] | None = None) -> None:
    """Entry point."""
    args = parse_args(argv)

    # Configure logging
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    elif args.quiet:
        logging.basicConfig(level=logging.ERROR)
    else:
        logging.basicConfig(level=logging.WARNING)

    handler = _DISPATCH.get(args.command)
    if handler is None:
        print(f"Unknown command: {args.command}", file=sys.stderr)
        sys.exit(1)
    handler(args)


if __name__ == "__main__":
    main()
```

---

## Completion Checklist

- [ ] Test file exists at `scripts/tests/test_<tool_name>.py`
- [ ] Implementation at `scripts/<tool_name>.py`
- [ ] All tests pass: `python3 -m pytest tests/ -v`
- [ ] Type check: `mypy --strict <tool_name>.py`
- [ ] Lint: `ruff check .`
- [ ] Format: `ruff format --check .`
- [ ] `nix flake check` passes
- [ ] Nix package definition created (if applicable)
