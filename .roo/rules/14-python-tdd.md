# Python TDD Workflow — Red-Green-Refactor for Python Code

## Rule ID: PY-TDD-001

**Priority**: MANDATORY  
**Applies to**: All Python code changes in `scripts/` and `tests/`

## Relationship to TEST-FIRST-001

This rule extends [`13-test-first.md`](13-test-first.md) (TEST-FIRST-001) with Python-specific procedures. The Red-Green-Refactor cycle from TEST-FIRST-001 applies. This rule defines HOW to execute it for Python code.

## Mandatory Test-First

- No production Python code without a prior failing test.
- Cycle: Red → Green → Refactor. No phase may be skipped.

## Red-Green-Refactor for Python

1. **Red**: Write failing test → `cd scripts && python3 -m pytest tests/<test_file>.py -v` → FAIL
2. **Green**: Write minimal implementation → same command → PASS
3. **Refactor**: Restructure while tests pass → same command → PASS

## Test Framework and Location

- Framework: `pytest`
- Test location: `scripts/tests/`
- Test files mirror source: `scripts/<tool>.py` → `scripts/tests/test_<tool>.py`
- `scripts/tests/__init__.py` must exist (package marker)

## Minimum Test Coverage per CLI Tool

Every CLI command requires at minimum:

- Unit tests for business logic (API calls mocked)
- A test for exit code ≠ 0 on failure
- A test for `--help` output (via `parse_args(['--help'])` with `SystemExit` catch)

## Mocking External APIs

- Mock external APIs with `unittest.mock.patch`, `pytest-mock`, or `responses`.
- No real API calls in tests. All HTTP interactions must be mocked.
- Use dependency injection pattern (injectable `auth`, `client` parameters) for testability (see PY-CLI-001, Command Handler Pattern).

## Property-Based Testing

- Consider property-based testing with `hypothesis` when input domain is non-trivial (e.g., firewall rule validation, IP address parsing).
- Not mandatory for every function — use when input space is large or combinatorial.

## Test Naming Convention

- Test classes: `Test<Subject>` (e.g., `TestArgParsing`, `TestBackupCommand`)
- Test methods: `test_<verb>_<subject_or_condition>` (e.g., `test_parse_backup_command`, `test_exit_nonzero_on_api_error`)

## Exceptions

Exceptions inherited from TEST-FIRST-001. Python-relevant exceptions:

- Documentation-only changes (`.md` files)
- Formatting-only changes

## Verification Commands

| Command | Purpose |
|---------|---------|
| `cd scripts && python3 -m pytest tests/ -v` | Run all Python tests |
| `cd scripts && python3 -m pytest tests/test_<tool>.py -v` | Run tests for specific tool |
| `cd scripts && python3 -m pytest tests/ -v --tb=short` | Run with short tracebacks |

## Shared Fixtures

- Shared fixtures and `sys.path` manipulation belong in `scripts/tests/conftest.py`.
- Each test module imports fixtures by name; do not repeat fixture definitions across modules.

## Parametrized Tests

- Use `@pytest.mark.parametrize` for testing multiple invalid input variations of the same argument or command.
- Avoids repetitive test methods for boundary conditions.

## Error Message Assertions

- Tests for error conditions SHOULD assert both exit code AND error message content using `capsys.readouterr()`.
- Exit-code-only assertions leave error message regressions undetected.
