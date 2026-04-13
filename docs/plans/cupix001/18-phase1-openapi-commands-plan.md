# Implementation Plan: CUP-018 Phase 1 — OpenAPI Commands

**Parent Story:** [18-scp-cli-restructuring.md](18-scp-cli-restructuring.md)
**Status:** COMPLETED
**Phase:** 1 of 4

---

## 1. Goal and Context

### Goal

Add an `openapi` subcommand group with two commands to [`scripts/netcup_firewall.py`](../../../scripts/netcup_firewall.py):

1. `netcup-scp openapi download --output <path>` — downloads the OpenAPI spec via `GET /api/v1/openapi`
2. `netcup-scp openapi mcp --message <text>` — sends a message to `POST /api/v1/openapi/mcp`

### Context

The existing CLI has flat subcommands (`backup`, `lockdown`, `restore`, `apply`, `ssh-open`, `ssh-close`). Phase 1 introduces the first **nested subcommand group** (`openapi` → `download` | `mcp`), which establishes the pattern for Phase 3a (`server firewall`) and Phase 3b (`policy`).

Neither command requires `user_id` — they operate on unauthenticated-user-level API endpoints (only bearer token needed). This simplifies the handler signatures compared to existing commands.

### Constraints

- No real API calls — the user cannot execute the script against the SCP API. All API interaction is mocked in tests.
- Existing 109+ tests must continue to pass after all changes.
- Follow existing patterns: DI injection, `_authenticate_and_setup`, `args.func` dispatch.
- Quality gates: `mypy --strict`, `ruff check`, `ruff format --check`.

---

## 2. Acceptance Criteria

### Scenario 1.1: Download and save the SCP OpenAPI spec

**Given** the operator is authenticated (valid OIDC token)
**When** they run `netcup-scp openapi download --output /tmp/scp-openapi.json`
**Then** the tool performs `GET /api/v1/openapi` with the bearer token
**And** saves the response body as valid JSON to `/tmp/scp-openapi.json`
**And** prints `Saved OpenAPI spec to /tmp/scp-openapi.json` to stdout
**And** exits with code `0`

### Scenario 1.2: Download fails when unauthenticated

**Given** the operator has no valid credentials
**When** they run `netcup-scp openapi download --output /tmp/scp-openapi.json`
**Then** the tool prints an authentication error message to stderr
**And** exits with code `1`
**And** does NOT create or overwrite the output file

### Scenario 1.3: Explore the MCP endpoint

**Given** the operator is authenticated
**When** they run `netcup-scp openapi mcp --message "list available tools"`
**Then** the tool performs `POST /api/v1/openapi/mcp` with the bearer token and the message body
**And** prints the MCP response JSON to stdout
**And** exits with code `0`

### Scenario 1.4: Download output path is not writable

**Given** the operator is authenticated
**When** they run `netcup-scp openapi download --output /root/protected/spec.json`
**And** the output directory does not exist or is not writable
**Then** the tool prints a permission error to stderr
**And** exits with code `1`

---

## 3. Technical Analysis

### 3.1 New API Client Methods on `ScpApiClient`

Two new public methods on [`ScpApiClient`](../../../scripts/netcup_firewall.py:340):

| Method | HTTP Call | Returns |
|--------|-----------|---------|
| `get_openapi_spec()` | `self._get("/openapi")` | `dict[str, Any]` (parsed JSON) |
| `post_openapi_mcp(message: str)` | `self._post("/openapi/mcp", {"message": message})` | `dict[str, Any]` (parsed JSON) |

Both leverage existing [`_get()`](../../../scripts/netcup_firewall.py:367) and [`_post()`](../../../scripts/netcup_firewall.py:375) private helpers — no new HTTP plumbing needed. The retry logic, timeout, and `raise_for_status()` are inherited.

### 3.2 Argparse Structure — Nested Subcommand Group

Current structure (flat):

```
netcup-firewall
├── backup
├── lockdown
├── restore
├── apply
├── ssh-open
└── ssh-close
```

New structure (with nested group):

```
netcup-firewall
├── backup
├── lockdown
├── restore
├── apply
├── ssh-open
├── ssh-close
└── openapi          ← new subparser
    ├── download     ← sub-subparser, --output required
    └── mcp          ← sub-subparser, --message required
```

Implementation in [`parse_args()`](../../../scripts/netcup_firewall.py:1304):

```python
# openapi subcommand group
openapi_parser = subparsers.add_parser("openapi", help="OpenAPI spec operations.")
openapi_sub = openapi_parser.add_subparsers(dest="openapi_command")
openapi_sub.required = True

# openapi download
dl_parser = openapi_sub.add_parser("download", help="Download the OpenAPI spec.")
dl_parser.add_argument("--output", required=True, help="Output file path.")
dl_parser.set_defaults(command="openapi", func=cmd_openapi_download)

# openapi mcp
mcp_parser = openapi_sub.add_parser("mcp", help="Send a message to the MCP endpoint.")
mcp_parser.add_argument("--message", required=True, help="Message text.")
mcp_parser.set_defaults(command="openapi", func=cmd_openapi_mcp)
```

### 3.3 New Command Handler Functions

Two new handlers following the existing pattern from [`cmd_backup()`](../../../scripts/netcup_firewall.py:515) et al., but **without `user_id`**:

#### `cmd_openapi_download`

```python
def cmd_openapi_download(
    args: argparse.Namespace,
    *,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
) -> None:
```

Logic:
1. Authenticate via `_authenticate_and_setup()` (passing `user_id=0` as dummy, or use a simplified auth helper — see section 3.4)
2. Call `client.get_openapi_spec()`
3. Write JSON to `args.output` path
4. Print confirmation to stdout
5. On `OSError` (unwritable path): print error to stderr, exit 1

#### `cmd_openapi_mcp`

```python
def cmd_openapi_mcp(
    args: argparse.Namespace,
    *,
    auth: ScpAuth | None = None,
    client: ScpApiClient | None = None,
) -> None:
```

Logic:
1. Authenticate via `_authenticate_and_setup()` (same approach)
2. Call `client.post_openapi_mcp(args.message)`
3. Print response JSON to stdout

### 3.4 Integration with Existing Auth Flow

The existing [`_authenticate_and_setup()`](../../../scripts/netcup_firewall.py:555) returns `tuple[ScpAuth, ScpApiClient, int]` (auth, client, user_id). The openapi commands do not need `user_id`.

**Approach:** Create a lightweight wrapper `_authenticate_and_setup_no_user()` that:
- Accepts `auth: ScpAuth | None` and `client: ScpApiClient | None`
- When either is `None`, creates `ScpAuth`, calls `get_access_token()`, creates `ScpApiClient`
- Returns `tuple[ScpAuth, ScpApiClient]` — no `get_user_id()` call
- Avoids an unnecessary API call to `/userinfo`

This keeps the existing `_authenticate_and_setup()` untouched (no regression risk) while providing a cleaner interface for commands that do not need user context.

### 3.5 Test Patterns to Follow

Based on the existing test suite in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py):

| Pattern | Used For | Example |
|---------|----------|---------|
| Pattern B: `patch.object(client._session, "get")` | `ScpApiClient` unit tests | [`TestScpApiClient.test_find_server()`](../../../scripts/tests/test_netcup_firewall.py:354) |
| Pattern A: `@patch("netcup_firewall.ScpApiClient")` + `@patch("netcup_firewall.ScpAuth")` | Command handler tests | [`TestBackupCommand.test_backup_calls_api_methods()`](../../../scripts/tests/test_netcup_firewall.py:547) |
| DI injection | Command handler unit tests | Pass mock auth/client directly to handler |
| `argparse.Namespace(...)` | Handler tests without argparse | [`TestBackupCommand`](../../../scripts/tests/test_netcup_firewall.py:515) |

---

## 4. Implementation Phases (Red-Green-Refactor Cycles)

### Phase 1: `ScpApiClient.get_openapi_spec()`

#### Cycle 1.1 — Red: Test `get_openapi_spec()` returns parsed JSON

- [x] Add test class `TestScpApiClientOpenapi` in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py)
- [x] Add method `test_get_openapi_spec()`:
  - Create `ScpApiClient("fake-token")`
  - `patch.object(client._session, "get")` returning mock response with `{"openapi": "3.0.3", "info": {...}}`
  - Assert return value is the parsed dict
  - Assert `_session.get` called with URL ending in `/openapi`
- [x] Run: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestScpApiClientOpenapi -v` → FAIL (method does not exist)

#### Cycle 1.2 — Green: Implement `get_openapi_spec()`

- [x] Add method to [`ScpApiClient`](../../../scripts/netcup_firewall.py:340):
  ```python
  def get_openapi_spec(self) -> dict[str, Any]:
      resp = self._get("/openapi")
      return resp.json()
  ```
- [x] Run: same test → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass (no regressions)

### Phase 2: `ScpApiClient.post_openapi_mcp(message)`

#### Cycle 2.1 — Red: Test `post_openapi_mcp()` sends message and returns parsed JSON

- [x] Add method `test_post_openapi_mcp()` in `TestScpApiClientOpenapi`:
  - `patch.object(client._session, "post")` returning mock MCP response
  - Call `client.post_openapi_mcp("list available tools")`
  - Assert return value is parsed dict
  - Assert `_session.post` called with URL ending in `/openapi/mcp` and JSON body `{"message": "list available tools"}`
- [x] Run: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestScpApiClientOpenapi::test_post_openapi_mcp -v` → FAIL

#### Cycle 2.2 — Green: Implement `post_openapi_mcp()`

- [x] Add method to [`ScpApiClient`](../../../scripts/netcup_firewall.py:340):
  ```python
  def post_openapi_mcp(self, message: str) -> dict[str, Any]:
      resp = self._post("/openapi/mcp", {"message": message})
      return resp.json()
  ```
- [x] Run: same test → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 3: Argparse — `openapi download` subcommand

#### Cycle 3.1 — Red: Test `openapi download` parsing

- [x] Add test class `TestOpenApiArgParsing` in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py)
- [x] Add method `test_openapi_download_subcommand()`:
  - `parse_args(["openapi", "download", "--output", "/tmp/spec.json"])`
  - Assert `args.command == "openapi"`
  - Assert `args.output == "/tmp/spec.json"`
  - Assert `args.func is cmd_openapi_download`
- [x] Add method `test_openapi_download_requires_output()`:
  - `parse_args(["openapi", "download"])` → `pytest.raises(SystemExit)`
- [x] Update import block to include `cmd_openapi_download`
- [x] Run: → FAIL (import error, command not defined)

#### Cycle 3.2 — Green: Implement `openapi download` in `parse_args()`

- [x] Add `openapi` subparser group and `download` sub-subparser to [`parse_args()`](../../../scripts/netcup_firewall.py:1304)
- [x] Create stub `cmd_openapi_download()` handler (just `pass`) to satisfy the import and `args.func` reference
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 4: Argparse — `openapi mcp` subcommand

#### Cycle 4.1 — Red: Test `openapi mcp` parsing

- [x] Add method `test_openapi_mcp_subcommand()` in `TestOpenApiArgParsing`:
  - `parse_args(["openapi", "mcp", "--message", "list tools"])`
  - Assert `args.command == "openapi"`
  - Assert `args.message == "list tools"`
  - Assert `args.func is cmd_openapi_mcp`
- [x] Add method `test_openapi_mcp_requires_message()`:
  - `parse_args(["openapi", "mcp"])` → `pytest.raises(SystemExit)`
- [x] Add method `test_openapi_requires_subcommand()`:
  - `parse_args(["openapi"])` → `pytest.raises(SystemExit)`
- [x] Update import block to include `cmd_openapi_mcp`
- [x] Run: → FAIL (import error)

#### Cycle 4.2 — Green: Implement `openapi mcp` in `parse_args()`

- [x] Add `mcp` sub-subparser to the openapi subparser group
- [x] Create stub `cmd_openapi_mcp()` handler (just `pass`)
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 5: `_authenticate_and_setup_no_user()`

#### Cycle 5.1 — Red: Test the no-user auth helper

- [x] Add test class `TestAuthenticateNoUser` in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py)
- [x] Add method `test_creates_auth_and_client_when_none()`:
  - `@patch("netcup_firewall.ScpApiClient")` + `@patch("netcup_firewall.ScpAuth")`
  - Call `_authenticate_and_setup_no_user(None, None)`
  - Assert `ScpAuth()` called, `get_access_token()` called, `ScpApiClient(token)` called
  - Assert `get_user_id()` NOT called
  - Assert returns `(auth, client)` tuple
- [x] Add method `test_returns_provided_auth_and_client()`:
  - Pass mock auth and client → returns them unchanged
- [x] Update import block to include `_authenticate_and_setup_no_user`
- [x] Run: → FAIL (function does not exist)

#### Cycle 5.2 — Green: Implement `_authenticate_and_setup_no_user()`

- [x] Add function after [`_authenticate_and_setup()`](../../../scripts/netcup_firewall.py:555):
  ```python
  def _authenticate_and_setup_no_user(
      auth: ScpAuth | None,
      client: ScpApiClient | None,
      use_keyring: bool = False,
  ) -> tuple[ScpAuth, ScpApiClient]:
      if auth is None or client is None:
          _auth = ScpAuth(use_keyring=use_keyring)
          access_token = _auth.get_access_token()
          _client = ScpApiClient(access_token)
          return _auth, _client
      return auth, client
  ```
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 6: `cmd_openapi_download` — success path (Scenario 1.1)

#### Cycle 6.1 — Red: Test download writes JSON and prints confirmation

- [x] Add test class `TestOpenApiDownloadCommand` in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py)
- [x] Add method `test_download_saves_spec_to_file()`:
  - Create `argparse.Namespace(output=str(tmp_path / "spec.json"), command="openapi")`
  - Create mock client with `get_openapi_spec()` returning `{"openapi": "3.0.3"}`
  - Create mock auth
  - Call `cmd_openapi_download(args, auth=mock_auth, client=mock_client)`
  - Assert file exists at output path
  - Assert file content is valid JSON matching the mock response
  - Assert stdout (via `capsys`) contains `Saved OpenAPI spec to`
- [x] Run: → FAIL (handler is a stub)

#### Cycle 6.2 — Green: Implement download success path

- [x] Replace stub `cmd_openapi_download()` with full implementation:
  - Call `_authenticate_and_setup_no_user(auth, client, use_keyring=...)`
  - Call `client.get_openapi_spec()`
  - Write JSON to `args.output` with `json.dump()`
  - Print confirmation message
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 7: `cmd_openapi_download` — auth failure (Scenario 1.2)

#### Cycle 7.1 — Red: Test download fails on auth error

- [x] Add method `test_download_auth_failure()` in `TestOpenApiDownloadCommand`:
  - `@patch("netcup_firewall.ScpApiClient")` + `@patch("netcup_firewall.ScpAuth")`
  - Configure `ScpAuth().get_access_token()` to raise `requests.HTTPError`
  - Create `argparse.Namespace(output=str(tmp_path / "spec.json"), command="openapi", keyring=False, verbose=False)`
  - Call `main(["openapi", "download", "--output", str(tmp_path / "spec.json")])` or invoke handler directly
  - Assert `SystemExit` with code `1` (auth errors bubble up through `main()` exception handler)
  - Assert output file does NOT exist
- [x] Run: → FAIL

#### Cycle 7.2 — Green: Verify auth failure propagation

- [x] Auth errors from `_authenticate_and_setup_no_user()` propagate as exceptions. The existing [`main()`](../../../scripts/netcup_firewall.py:1431) catches `Exception` and calls `sys.exit(1)`. Verify this path works without additional code.
- [x] If the test already passes due to existing exception handling, mark as trivially green. If not, add specific error handling.
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 8: `cmd_openapi_download` — write failure (Scenario 1.4)

#### Cycle 8.1 — Red: Test download fails on unwritable path

- [x] Add method `test_download_unwritable_path()` in `TestOpenApiDownloadCommand`:
  - Create mock client with `get_openapi_spec()` returning valid data
  - Set `args.output` to a path in a non-existent or read-only directory
  - Call `cmd_openapi_download(args, auth=mock_auth, client=mock_client)`
  - Assert raises `OSError` / `PermissionError` (or `SystemExit(1)` if caught internally)
  - Assert stderr contains permission/path error message
- [x] Run: → FAIL

#### Cycle 8.2 — Green: Add write error handling

- [x] Wrap `json.dump()` in `try/except OSError` in `cmd_openapi_download()`:
  - On `OSError`: log error to stderr, raise `SystemExit(1)`
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 9: `cmd_openapi_mcp` — success path (Scenario 1.3)

#### Cycle 9.1 — Red: Test MCP prints response JSON to stdout

- [x] Add test class `TestOpenApiMcpCommand` in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py)
- [x] Add method `test_mcp_prints_response_json()`:
  - Create `argparse.Namespace(message="list available tools", command="openapi")`
  - Create mock client with `post_openapi_mcp()` returning `{"tools": ["firewall", "server"]}`
  - Call `cmd_openapi_mcp(args, auth=mock_auth, client=mock_client)`
  - Assert stdout (via `capsys`) contains the JSON response
- [x] Run: → FAIL (handler is a stub)

#### Cycle 9.2 — Green: Implement MCP success path

- [x] Replace stub `cmd_openapi_mcp()` with full implementation:
  - Call `_authenticate_and_setup_no_user(auth, client, use_keyring=...)`
  - Call `client.post_openapi_mcp(args.message)`
  - Print `json.dumps(result, indent=2)` to stdout
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 10: `cmd_openapi_mcp` — auth failure

#### Cycle 10.1 — Red: Test MCP fails on auth error

- [x] Add method `test_mcp_auth_failure()` in `TestOpenApiMcpCommand`:
  - Same pattern as Cycle 7.1 but for the `mcp` subcommand
  - Assert `SystemExit(1)` via `main()` exception path
- [x] Run: → FAIL

#### Cycle 10.2 — Green: Verify auth failure propagation

- [x] Same as Cycle 7.2 — auth errors propagate through `main()` exception handler
- [x] Run: → PASS
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all pass

### Phase 11: Import and Integration Verification

#### Cycle 11.1 — Verify imports in test file

- [x] Confirm import block in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py:21) includes all new symbols:
  - `cmd_openapi_download`
  - `cmd_openapi_mcp`
  - `_authenticate_and_setup_no_user`
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all 109+ existing tests + all new tests pass

#### Cycle 11.2 — Verify `main()` dispatch for openapi commands

- [x] Add method `test_main_dispatches_openapi_download()` in `TestMain`:
  - `@patch("netcup_firewall.cmd_openapi_download")`
  - Call `main(["openapi", "download", "--output", "/tmp/spec.json"])`
  - Assert `cmd_openapi_download` was called
- [x] Add method `test_main_dispatches_openapi_mcp()` in `TestMain`:
  - `@patch("netcup_firewall.cmd_openapi_mcp")`
  - Call `main(["openapi", "mcp", "--message", "hello"])`
  - Assert `cmd_openapi_mcp` was called
- [x] Run: → PASS (should work if argparse wiring is correct)

### Phase 12: Quality Gates

- [x] Run: `cd scripts && mypy --strict netcup_firewall.py` → zero errors
- [x] Run: `cd scripts && ruff check .` → zero violations
- [x] Run: `cd scripts && ruff format --check .` → no changes needed
- [x] Run: `cd scripts && python3 -m pytest tests/ -v` → all tests pass
- [x] Commit: `feat(scripts): add openapi download and mcp commands (CUP-018 Phase 1)`

---

## 5. Validation Strategy

### Regression Safety

- All existing 109+ tests in [`test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py) must pass after every cycle
- No modification to existing test classes or methods
- No modification to existing command handlers

### New Test Coverage

| Test Class | Tests | Covers |
|------------|-------|--------|
| `TestScpApiClientOpenapi` | 2 | `get_openapi_spec()`, `post_openapi_mcp()` |
| `TestOpenApiArgParsing` | 5 | Parsing both subcommands, required args, `func` binding |
| `TestAuthenticateNoUser` | 2 | Auth helper without user_id |
| `TestOpenApiDownloadCommand` | 3 | Success, auth failure, write failure |
| `TestOpenApiMcpCommand` | 2 | Success, auth failure |
| `TestMain` (additions) | 2 | Dispatch for both new commands |
| **Total new tests** | **16** | |

### Quality Gates Checklist

- [x] `mypy --strict` passes (zero errors)
- [x] `ruff check` passes (zero violations)
- [x] `ruff format --check` passes (no formatting changes)
- [x] All public functions have Google-style docstrings
- [x] Module-level import block updated with new symbols

### Files Modified

| File | Changes |
|------|---------|
| [`scripts/netcup_firewall.py`](../../../scripts/netcup_firewall.py) | Add 2 `ScpApiClient` methods, 1 auth helper, 2 command handlers, argparse subgroup |
| [`scripts/tests/test_netcup_firewall.py`](../../../scripts/tests/test_netcup_firewall.py) | Add 5 test classes with ~16 test methods |

### Rollback Path

All changes are additive (new methods, new subparser, new handlers). Rollback = revert the commit. No existing behavior is modified.

---

## 6. Current Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | `ScpApiClient.get_openapi_spec()` | ✅ Completed |
| 2 | `ScpApiClient.post_openapi_mcp()` | ✅ Completed |
| 3 | Argparse: `openapi download` | ✅ Completed |
| 4 | Argparse: `openapi mcp` | ✅ Completed |
| 5 | `_authenticate_and_setup_no_user()` | ✅ Completed |
| 6 | `cmd_openapi_download` — success | ✅ Completed |
| 7 | `cmd_openapi_download` — auth failure | ✅ Completed |
| 8 | `cmd_openapi_download` — write failure | ✅ Completed |
| 9 | `cmd_openapi_mcp` — success | ✅ Completed |
| 10 | `cmd_openapi_mcp` — auth failure | ✅ Completed |
| 11 | Import and integration verification | ✅ Completed |
| 12 | Quality gates | ✅ Completed |

---

## Completion Log

| Phase | Status | Notes |
|-------|--------|-------|
| 1-2 | ✅ | API client methods added, 134→134 tests |
| 5 | ✅ | Auth helper without user_id, 134→136 tests |
| 3-4 | ✅ | Argparse nested subcommand group, 136→141 tests |
| 6-8 | ✅ | Download handler (success + auth fail + write fail), 141→144 tests |
| 9-10 | ✅ | MCP handler (success + auth fail), 144→146 tests |
| 11-12 | ✅ | Integration tests + quality gates + commit e1d5ed7, 146→148 tests |
