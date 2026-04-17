# Implementation Plan: CUP-018 Phase 3 — Server Firewall & Policy CRUD Commands

**Status:** COMPLETED
**Parent Story:** [CUP-018 SCP CLI Restructuring](18-scp-cli-restructuring.md)
**Phases Covered:** 3a (server firewall get/set), 3b (policy list/create/update/delete)

---

## Business Context

Phase 3 adds two command groups to the `netcup-scp` CLI:

- **`server firewall get/set`** — read and write per-interface firewall state on a named server
- **`policy list/create/update/delete`** — full CRUD for user-owned reusable firewall policies

These commands expose existing [`ScpApiClient`](../../scripts/netcup_firewall.py:340) methods through clean, independent subcommands, replacing the implicit policy operations currently embedded in `backup`, `lockdown`, and `ssh-open/close`.

## Acceptance Criteria

Scenarios 3a.1–3a.5 and 3b.1–3b.9 from [18-scp-cli-restructuring.md](18-scp-cli-restructuring.md).

## Technical Analysis

### Current State

| Aspect | Detail |
|--------|--------|
| Source file | [`scripts/netcup_firewall.py`](../../scripts/netcup_firewall.py) (1543 lines) |
| Test file | [`scripts/tests/test_netcup_firewall.py`](../../scripts/tests/test_netcup_firewall.py) (2660 lines, 146 tests) |
| Dispatch | `args.func` via `set_defaults(func=...)` — no `_DISPATCH` dict |
| Auth helpers | [`_authenticate_and_setup()`](../../scripts/netcup_firewall.py:565) (with user_id), [`_authenticate_and_setup_no_user()`](../../scripts/netcup_firewall.py:594) (without user_id) |
| DI pattern | `cmd_xxx(args, *, auth=None, client=None, user_id=None)` |
| API client | [`ScpApiClient`](../../scripts/netcup_firewall.py:340) using `requests.Session` with retry |
| Argparse | [`parse_args()`](../../scripts/netcup_firewall.py:1374) at lines 1374–1513 |
| Global flags | `--verbose`, `--quiet`, `--keyring` on root parser |

### What Already Exists in ScpApiClient

- [`find_server()`](../../scripts/netcup_firewall.py:399) — resolves name → ID
- [`get_firewall()`](../../scripts/netcup_firewall.py:437) — GET interface firewall state
- [`set_firewall()`](../../scripts/netcup_firewall.py:450) — PUT firewall (returns task UUID)
- [`wait_for_task()`](../../scripts/netcup_firewall.py:536) — poll async task
- [`list_policies()`](../../scripts/netcup_firewall.py:480) — GET all user policies
- [`create_policy()`](../../scripts/netcup_firewall.py:505) — POST new policy
- [`delete_policy()`](../../scripts/netcup_firewall.py:527) — DELETE policy
- [`_find_policy_by_name()`](../../scripts/netcup_firewall.py:773) — linear scan helper

### What Must Be Added

| Component | Location | Why |
|-----------|----------|-----|
| `--output {text,json}` global flag | [`parse_args()`](../../scripts/netcup_firewall.py:1374) | Required by `get` and `list` commands (PY-CLI-001) |
| `update_policy()` method | [`ScpApiClient`](../../scripts/netcup_firewall.py:340) | PUT `/users/{uid}/firewall-policies/{id}` — needed by `policy update` |
| `server` subcommand group | [`parse_args()`](../../scripts/netcup_firewall.py:1374) | Nested: `server firewall get`, `server firewall set` |
| `policy` subcommand group | [`parse_args()`](../../scripts/netcup_firewall.py:1374) | `policy list`, `policy create`, `policy update`, `policy delete` |
| `cmd_server_firewall_get()` | new handler | Scenario 3a.1, 3a.2, 3a.5 |
| `cmd_server_firewall_set()` | new handler | Scenario 3a.3, 3a.4 |
| `cmd_policy_list()` | new handler | Scenario 3b.1, 3b.2 |
| `cmd_policy_create()` | new handler | Scenario 3b.3, 3b.4, 3b.9 |
| `cmd_policy_update()` | new handler | Scenario 3b.5 |
| `cmd_policy_delete()` | new handler | Scenario 3b.6, 3b.7, 3b.8 |

### Design Decision: Use ScpApiClient, Not Generated Client

All new commands use the hand-written [`ScpApiClient`](../../scripts/netcup_firewall.py:340) for consistency:
1. All existing commands use `ScpApiClient` with `requests.Session`
2. The DI pattern is built around `ScpApiClient`
3. Mixing `requests` and `httpx` adds complexity for no benefit in this phase
4. Only one method is missing: `update_policy()`
5. The generated `scp_client` can be used in a future migration (out of scope)

### Argparse Nesting Strategy

```
netcup-scp
├── backup / lockdown / restore / apply / ssh-open / ssh-close  (existing flat)
├── openapi                                                      (existing nested)
│   ├── download
│   └── mcp
├── server                                                       (NEW nested)
│   └── firewall
│       ├── get   --server NAME --mac MAC [--output {text,json}]
│       └── set   --server NAME --mac MAC --policy-ids ID1,ID2 [--yes]
└── policy                                                       (NEW nested)
    ├── list      [--output {text,json}]
    ├── create    --name NAME --rules-file PATH
    ├── update    --name NAME --rules-file PATH [--yes]
    └── delete    --name NAME [--yes]
```

The `--output` flag is added to the root parser globally, defaulting to `text`. Commands that support it read `args.output`; commands that do not simply ignore the attribute.

---

## Phase 0: Validation Strategy

### Validation Commands

| Check | Command |
|-------|---------|
| Unit tests | `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v` |
| Type check | `cd scripts && mypy --strict netcup_firewall.py` |
| Lint | `cd scripts && ruff check .` |
| Format | `cd scripts && ruff format --check .` |
| Regression | All 146 existing tests must remain green after every cycle |

### Rollback Path

All changes are in two files: [`scripts/netcup_firewall.py`](../../scripts/netcup_firewall.py) and [`scripts/tests/test_netcup_firewall.py`](../../scripts/tests/test_netcup_firewall.py). Rollback via `git checkout -- scripts/netcup_firewall.py scripts/tests/test_netcup_firewall.py`.

### Dangerous Changes

None. This phase adds CLI commands only — no system services, networking, boot, or secrets changes.

---

## Implementation Phases

### Phase 1: Global `--output` Flag (Prerequisite)

Add `--output {text,json}` to the root argparse parser. Default: `text`. This is a prerequisite for both 3a and 3b commands that support `--output`.

#### Cycle 1.1 — Parse `--output` flag

- **Red**: `TestArgParsing.test_output_flag_default` — assert `parse_args(["backup", "--server", "x"]).output == "text"`
- **Green**: Add `parser.add_argument("--output", choices=["text", "json"], default="text", ...)` to [`parse_args()`](../../scripts/netcup_firewall.py:1374), after the `--keyring` argument (around line 1415)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestArgParsing::test_output_flag_default -v`

#### Cycle 1.2 — Parse `--output json` explicitly

- **Red**: `TestArgParsing.test_output_flag_json` — assert `parse_args(["--output", "json", "backup", "--server", "x"]).output == "json"`
- **Green**: Already works from cycle 1.1 — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestArgParsing::test_output_flag_json -v`

#### Cycle 1.3 — Invalid `--output` value rejected

- **Red**: `TestArgParsing.test_output_flag_invalid` — assert `parse_args(["--output", "xml", "backup", "--server", "x"])` raises `SystemExit`
- **Green**: Already enforced by `choices=["text", "json"]` — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestArgParsing::test_output_flag_invalid -v`

---

### Phase 2: `update_policy()` API Method (Prerequisite for 3b)

Add `update_policy()` to [`ScpApiClient`](../../scripts/netcup_firewall.py:340). Signature: `update_policy(self, user_id: int, policy_id: int, name: str, rules: list[dict[str, Any]]) -> dict[str, Any]`. Uses `self._put()` to `PUT /users/{user_id}/firewall-policies/{policy_id}`.

#### Cycle 2.1 — `update_policy()` sends PUT and returns response

- **Red**: `TestScpApiClient.test_update_policy_success` — mock `_put` to return `{"id": 123, "name": "updated", "rules": [...]}`, assert return value matches
- **Green**: Add `update_policy()` method to [`ScpApiClient`](../../scripts/netcup_firewall.py:340), after [`delete_policy()`](../../scripts/netcup_firewall.py:527) (around line 535)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestScpApiClient::test_update_policy_success -v`

#### Cycle 2.2 — `update_policy()` propagates HTTP errors

- **Red**: `TestScpApiClient.test_update_policy_http_error` — mock `_put` to raise `requests.HTTPError`, assert it propagates
- **Green**: Already works since `_put()` calls `raise_for_status()` — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestScpApiClient::test_update_policy_http_error -v`

---

### Phase 3a: Server Firewall Commands

#### Phase 3a-Parse: Argparse for `server firewall get/set`

##### Cycle 3a.1 — Parse `server firewall get` subcommand

- **Red**: `TestServerFirewallArgParsing.test_server_firewall_get_args` — assert `parse_args(["server", "firewall", "get", "--server", "cupix001", "--mac", "aa:bb:cc:dd:ee:ff"])` yields `args.server == "cupix001"`, `args.mac == "aa:bb:cc:dd:ee:ff"`, `args.func == cmd_server_firewall_get`
- **Green**: Add `server` subparser with nested `firewall` subparser, add `get` parser with `--server` and `--mac` arguments to [`parse_args()`](../../scripts/netcup_firewall.py:1374), before `return parser.parse_args(argv)` (around line 1511)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallArgParsing::test_server_firewall_get_args -v`

##### Cycle 3a.2 — Parse `server firewall set` subcommand with `--policy-ids` and `--yes`

- **Red**: `TestServerFirewallArgParsing.test_server_firewall_set_args` — assert `parse_args(["server", "firewall", "set", "--server", "cupix001", "--mac", "aa:bb:cc:dd:ee:ff", "--policy-ids", "42,99", "--yes"])` yields `args.policy_ids == "42,99"`, `args.yes is True`, `args.func == cmd_server_firewall_set`
- **Green**: Add `set` parser with `--server`, `--mac`, `--policy-ids`, `--yes` arguments to the `firewall` subparser group
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallArgParsing::test_server_firewall_set_args -v`

##### Cycle 3a.3 — `server firewall set` `--yes` defaults to False

- **Red**: `TestServerFirewallArgParsing.test_server_firewall_set_yes_default_false` — assert `parse_args(["server", "firewall", "set", "--server", "x", "--mac", "m", "--policy-ids", "1"]).yes is False`
- **Green**: Already works from cycle 3a.2 (`default=False`) — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallArgParsing::test_server_firewall_set_yes_default_false -v`

#### Phase 3a-Get: `cmd_server_firewall_get()` Handler

##### Cycle 3a.4 — Get firewall state, text output (Scenario 3a.1)

- **Red**: `TestServerFirewallGetCommand.test_get_firewall_text_output` — inject mock `client` with `find_server` returning `1`, `get_firewall` returning sample dict; assert stdout contains pretty-printed JSON, exit 0
- **Green**: Implement `cmd_server_firewall_get(args, *, auth=None, client=None)` — stub using `_authenticate_and_setup_no_user()`, call `client.find_server()`, `client.get_firewall()`, print via `json.dumps(data, indent=2)` for text mode. Place after [`_find_policy_by_name()`](../../scripts/netcup_firewall.py:773) (around line 790)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallGetCommand::test_get_firewall_text_output -v`

##### Cycle 3a.5 — Get firewall state, JSON output with snake_case keys (Scenario 3a.2)

- **Red**: `TestServerFirewallGetCommand.test_get_firewall_json_output` — set `args.output = "json"`, assert stdout is valid JSON with `lowercase_underscore` keys (`user_policies`, `copied_policies`, `ingress_implicit_rule`, `egress_implicit_rule`, `consistent`, `active`), no log messages on stdout
- **Green**: Add key-conversion logic in `cmd_server_firewall_get()`: when `args.output == "json"`, convert `camelCase` keys to `snake_case` before `json.dumps(data)`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallGetCommand::test_get_firewall_json_output -v`

##### Cycle 3a.6 — Server not found error (Scenario 3a.5)

- **Red**: `TestServerFirewallGetCommand.test_get_firewall_server_not_found` — mock `client.find_server` to raise `ValueError("Server 'nonexistent' not found")`, assert stderr contains `Error: server 'nonexistent' not found`, exit 1, no traceback
- **Green**: Add `try/except ValueError` in `cmd_server_firewall_get()` around `find_server()` call, print error to stderr, `sys.exit(1)`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallGetCommand::test_get_firewall_server_not_found -v`

#### Phase 3a-Set: `cmd_server_firewall_set()` Handler

##### Cycle 3a.7 — Set firewall with `--yes`, success (Scenario 3a.3)

- **Red**: `TestServerFirewallSetCommand.test_set_firewall_with_yes` — inject mock `client` with `find_server` returning `1`, `set_firewall` returning `"task-uuid"`, `wait_for_task` succeeding; set `args.yes = True`, `args.policy_ids = "42,99"`; assert `set_firewall` called with `(1, "mac", [42, 99])`, stdout contains success message, exit 0
- **Green**: Implement `cmd_server_firewall_set(args, *, auth=None, client=None)` — parse `args.policy_ids` by splitting on comma and converting to `list[int]`, call `client.find_server()`, `client.set_firewall()`, `client.wait_for_task()`, print success message
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallSetCommand::test_set_firewall_with_yes -v`

##### Cycle 3a.8 — Set firewall prompts without `--yes`, user confirms (Scenario 3a.4)

- **Red**: `TestServerFirewallSetCommand.test_set_firewall_prompts_and_confirms` — set `args.yes = False`, mock `builtins.input` to return `"y"`, assert `set_firewall` IS called, stdout contains prompt text
- **Green**: Add confirmation prompt in `cmd_server_firewall_set()` when `args.yes is False`: print prompt, read input, proceed only if `y`/`Y`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallSetCommand::test_set_firewall_prompts_and_confirms -v`

##### Cycle 3a.9 — Set firewall prompts without `--yes`, user declines (Scenario 3a.4)

- **Red**: `TestServerFirewallSetCommand.test_set_firewall_prompts_and_declines` — set `args.yes = False`, mock `builtins.input` to return `"n"`, assert `set_firewall` NOT called, stderr contains `Aborted.`, exit 1
- **Green**: Already covered by the prompt logic from 3a.8 — test confirms decline path
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallSetCommand::test_set_firewall_prompts_and_declines -v`

##### Cycle 3a.10 — Set firewall server not found

- **Red**: `TestServerFirewallSetCommand.test_set_firewall_server_not_found` — mock `client.find_server` to raise `ValueError`, assert stderr error, exit 1, `set_firewall` NOT called
- **Green**: Add `try/except ValueError` in `cmd_server_firewall_set()` (same pattern as get)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallSetCommand::test_set_firewall_server_not_found -v`

##### Cycle 3a.11 — Set firewall invalid policy-ids format

- **Red**: `TestServerFirewallSetCommand.test_set_firewall_invalid_policy_ids` — set `args.policy_ids = "abc,def"`, assert stderr error about invalid integer, exit 1
- **Green**: Add `try/except ValueError` around the `int()` conversion of policy IDs
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestServerFirewallSetCommand::test_set_firewall_invalid_policy_ids -v`

---

### Phase 3b: Policy CRUD Commands

#### Phase 3b-Parse: Argparse for `policy list/create/update/delete`

##### Cycle 3b.1 — Parse `policy list` subcommand

- **Red**: `TestPolicyArgParsing.test_policy_list_args` — assert `parse_args(["policy", "list"])` yields `args.func == cmd_policy_list`
- **Green**: Add `policy` subparser with `list` sub-subparser to [`parse_args()`](../../scripts/netcup_firewall.py:1374)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyArgParsing::test_policy_list_args -v`

##### Cycle 3b.2 — Parse `policy create` subcommand

- **Red**: `TestPolicyArgParsing.test_policy_create_args` — assert `parse_args(["policy", "create", "--name", "test", "--rules-file", "rules.json"])` yields `args.name == "test"`, `args.rules_file == "rules.json"`, `args.func == cmd_policy_create`
- **Green**: Add `create` parser with `--name` and `--rules-file` arguments
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyArgParsing::test_policy_create_args -v`

##### Cycle 3b.3 — Parse `policy update` subcommand with `--yes`

- **Red**: `TestPolicyArgParsing.test_policy_update_args` — assert `parse_args(["policy", "update", "--name", "test", "--rules-file", "rules.json", "--yes"])` yields `args.name == "test"`, `args.rules_file == "rules.json"`, `args.yes is True`, `args.func == cmd_policy_update`
- **Green**: Add `update` parser with `--name`, `--rules-file`, `--yes` arguments
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyArgParsing::test_policy_update_args -v`

##### Cycle 3b.4 — Parse `policy delete` subcommand with `--yes`

- **Red**: `TestPolicyArgParsing.test_policy_delete_args` — assert `parse_args(["policy", "delete", "--name", "test", "--yes"])` yields `args.name == "test"`, `args.yes is True`, `args.func == cmd_policy_delete`
- **Green**: Add `delete` parser with `--name`, `--yes` arguments
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyArgParsing::test_policy_delete_args -v`

##### Cycle 3b.5 — `policy update` and `policy delete` `--yes` defaults to False

- **Red**: `TestPolicyArgParsing.test_policy_update_yes_default_false` — assert `.yes is False` without `--yes`
- **Green**: Already works from `default=False` — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyArgParsing::test_policy_update_yes_default_false -v`

#### Phase 3b-List: `cmd_policy_list()` Handler

##### Cycle 3b.6 — List policies, text output, non-empty (Scenario 3b.1)

- **Red**: `TestPolicyListCommand.test_list_policies_text_output` — inject mock `client` with `list_policies` returning `[{"id": 42, "name": "lockdown", "rules": []}, {"id": 99, "name": "ssh-temp", "rules": [{"direction": "in", ...}]}]`; set `args.output = "text"`; assert stdout contains table with `ID`, `Name`, `Rules` columns, showing both policies with rule counts, exit 0
- **Green**: Implement `cmd_policy_list(args, *, auth=None, client=None, user_id=None)` — call `_authenticate_and_setup()`, `client.list_policies(user_id)`, format as table for text output. Place after `cmd_server_firewall_set()`.
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyListCommand::test_list_policies_text_output -v`

##### Cycle 3b.7 — List policies, JSON output (Scenario 3b.2)

- **Red**: `TestPolicyListCommand.test_list_policies_json_output` — set `args.output = "json"`, assert stdout is valid JSON array, each object has `id`, `name`, `rules` keys
- **Green**: Add JSON output branch to `cmd_policy_list()`: `json.dumps(policies)` to stdout
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyListCommand::test_list_policies_json_output -v`

##### Cycle 3b.8 — List policies, empty list

- **Red**: `TestPolicyListCommand.test_list_policies_empty` — mock `list_policies` returning `[]`, assert no crash, stdout indicates no policies or empty table, exit 0
- **Green**: Handle empty list in `cmd_policy_list()` — print empty table or message
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyListCommand::test_list_policies_empty -v`

#### Phase 3b-Create: `cmd_policy_create()` Handler

##### Cycle 3b.9 — Create policy success (Scenario 3b.3)

- **Red**: `TestPolicyCreateCommand.test_create_policy_success` — inject mock `client` with `list_policies` returning `[]` (no duplicate), `create_policy` returning `{"id": 123, "name": "test", "rules": [...]}`; mock `load_policy_file` returning valid policy dict; assert `create_policy` called with correct args, stdout contains `Created policy 'test' with ID 123`, exit 0
- **Green**: Implement `cmd_policy_create(args, *, auth=None, client=None, user_id=None)` — call `load_policy_file()`, `validate_policy_schema()`, check for duplicate via `_find_policy_by_name()`, then `client.create_policy()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyCreateCommand::test_create_policy_success -v`

##### Cycle 3b.10 — Create policy duplicate name error (Scenario 3b.4)

- **Red**: `TestPolicyCreateCommand.test_create_policy_duplicate_name` — mock `_find_policy_by_name` returning `{"id": 42, "name": "lockdown"}`, assert stderr contains `Error: policy named 'lockdown' already exists (ID 42)`, exit 1, `create_policy` NOT called
- **Green**: Add duplicate check before POST in `cmd_policy_create()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyCreateCommand::test_create_policy_duplicate_name -v`

##### Cycle 3b.11 — Create policy invalid rules file (Scenario 3b.9)

- **Red**: `TestPolicyCreateCommand.test_create_policy_invalid_rules_file` — mock `load_policy_file` returning dict with missing required fields, assert `validate_policy_schema` raises `ValueError`, stderr contains validation error, exit 2, no POST sent
- **Green**: Add `try/except ValueError` around `validate_policy_schema()`, `sys.exit(2)` on schema error
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyCreateCommand::test_create_policy_invalid_rules_file -v`

##### Cycle 3b.12 — Create policy file not found

- **Red**: `TestPolicyCreateCommand.test_create_policy_file_not_found` — mock `load_policy_file` raising `FileNotFoundError`, assert stderr error, exit 1
- **Green**: Add `try/except FileNotFoundError` in `cmd_policy_create()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyCreateCommand::test_create_policy_file_not_found -v`

#### Phase 3b-Update: `cmd_policy_update()` Handler

##### Cycle 3b.13 — Update policy success with `--yes` (Scenario 3b.5)

- **Red**: `TestPolicyUpdateCommand.test_update_policy_success` — inject mock `client` with `_find_policy_by_name` returning `{"id": 123, "name": "test"}`, `update_policy` returning updated dict; mock `load_policy_file` returning valid rules; set `args.yes = True`; assert `update_policy` called with `(user_id, 123, "test", rules)`, stdout contains `Updated policy 'test' (ID 123)`, exit 0
- **Green**: Implement `cmd_policy_update(args, *, auth=None, client=None, user_id=None)` — load + validate rules file, find policy by name, call `client.update_policy()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyUpdateCommand::test_update_policy_success -v`

##### Cycle 3b.14 — Update policy prompts without `--yes`, user confirms

- **Red**: `TestPolicyUpdateCommand.test_update_policy_prompts_and_confirms` — set `args.yes = False`, mock `builtins.input` returning `"y"`, assert `update_policy` IS called
- **Green**: Add confirmation prompt logic in `cmd_policy_update()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyUpdateCommand::test_update_policy_prompts_and_confirms -v`

##### Cycle 3b.15 — Update policy prompts without `--yes`, user declines

- **Red**: `TestPolicyUpdateCommand.test_update_policy_prompts_and_declines` — set `args.yes = False`, mock `builtins.input` returning `"n"`, assert `update_policy` NOT called, stderr `Aborted.`, exit 1
- **Green**: Decline path already covered by prompt logic — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyUpdateCommand::test_update_policy_prompts_and_declines -v`

##### Cycle 3b.16 — Update policy not found

- **Red**: `TestPolicyUpdateCommand.test_update_policy_not_found` — mock `_find_policy_by_name` returning `None`, assert stderr `Error: policy named 'nonexistent' not found`, exit 1, `update_policy` NOT called
- **Green**: Add not-found check in `cmd_policy_update()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyUpdateCommand::test_update_policy_not_found -v`

#### Phase 3b-Delete: `cmd_policy_delete()` Handler

##### Cycle 3b.17 — Delete policy with `--yes` (Scenario 3b.7)

- **Red**: `TestPolicyDeleteCommand.test_delete_policy_with_yes` — inject mock `client` with `_find_policy_by_name` returning `{"id": 99, "name": "ssh-temp"}`, `delete_policy` succeeding; set `args.yes = True`; assert `delete_policy` called with `(user_id, 99)`, stdout contains `Deleted policy 'ssh-temp' (ID 99)`, exit 0
- **Green**: Implement `cmd_policy_delete(args, *, auth=None, client=None, user_id=None)` — find by name, confirm, delete
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyDeleteCommand::test_delete_policy_with_yes -v`

##### Cycle 3b.18 — Delete policy prompts without `--yes`, user confirms (Scenario 3b.6)

- **Red**: `TestPolicyDeleteCommand.test_delete_policy_prompts_and_confirms` — set `args.yes = False`, mock `builtins.input` returning `"y"`, assert `delete_policy` IS called, stdout contains prompt and deletion message
- **Green**: Add confirmation prompt logic in `cmd_policy_delete()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyDeleteCommand::test_delete_policy_prompts_and_confirms -v`

##### Cycle 3b.19 — Delete policy prompts without `--yes`, user declines

- **Red**: `TestPolicyDeleteCommand.test_delete_policy_prompts_and_declines` — set `args.yes = False`, mock `builtins.input` returning `"n"`, assert `delete_policy` NOT called, stderr `Aborted.`, exit 1
- **Green**: Already covered by prompt logic — test confirms
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyDeleteCommand::test_delete_policy_prompts_and_declines -v`

##### Cycle 3b.20 — Delete policy not found (Scenario 3b.8)

- **Red**: `TestPolicyDeleteCommand.test_delete_policy_not_found` — mock `_find_policy_by_name` returning `None`, assert stderr `Error: policy named 'nonexistent-policy' not found`, exit 1, `delete_policy` NOT called
- **Green**: Add not-found check in `cmd_policy_delete()`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyDeleteCommand::test_delete_policy_not_found -v`

---

### Phase 4: Import Wiring & Quality Gate

##### Cycle 4.1 — Add new handlers to test imports

- **Red**: Update the import block at the top of [`scripts/tests/test_netcup_firewall.py`](../../scripts/tests/test_netcup_firewall.py:21) to import `cmd_server_firewall_get`, `cmd_server_firewall_set`, `cmd_policy_list`, `cmd_policy_create`, `cmd_policy_update`, `cmd_policy_delete` — if these are not yet exported, import will fail
- **Green**: Verify all six handlers are importable (they should be, since they are module-level functions)
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v` (full suite)

##### Cycle 4.2 — Full regression + quality gates

- **Red/Green**: Not a TDD cycle — this is a validation-only step
- Run all quality gates in sequence:

```bash
cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v
cd scripts && mypy --strict netcup_firewall.py
cd scripts && ruff check .
cd scripts && ruff format --check .
```

- All must pass with zero errors
- All 146+ existing tests must remain green

---

## Cycle Summary

| Phase | Cycles | Focus |
|-------|--------|-------|
| 1 | 1.1–1.3 | Global `--output` flag |
| 2 | 2.1–2.2 | `update_policy()` API method |
| 3a-Parse | 3a.1–3a.3 | `server firewall get/set` argparse |
| 3a-Get | 3a.4–3a.6 | `cmd_server_firewall_get()` handler |
| 3a-Set | 3a.7–3a.11 | `cmd_server_firewall_set()` handler |
| 3b-Parse | 3b.1–3b.5 | `policy list/create/update/delete` argparse |
| 3b-List | 3b.6–3b.8 | `cmd_policy_list()` handler |
| 3b-Create | 3b.9–3b.12 | `cmd_policy_create()` handler |
| 3b-Update | 3b.13–3b.16 | `cmd_policy_update()` handler |
| 3b-Delete | 3b.17–3b.20 | `cmd_policy_delete()` handler |
| 4 | 4.1–4.2 | Import wiring + full quality gate |
| **Total** | **33 cycles** | |

---

## Key Implementation Notes

### camelCase → snake_case Conversion (for `--output json`)

The SCP API returns `camelCase` keys (e.g., `userPolicies`, `copiedPolicies`, `ingressImplicitRule`). When `--output json` is specified, convert to `snake_case` for `jq` compatibility per PY-CLI-001. Use a simple regex-based converter:

```python
import re
def _camel_to_snake(name: str) -> str:
    return re.sub(r'(?<=[a-z0-9])([A-Z])', r'_\1', name).lower()
```

Apply recursively to dict keys. This helper is needed only by `cmd_server_firewall_get()` and `cmd_policy_list()`.

### Policy ID Parsing (for `--policy-ids`)

The `--policy-ids` argument accepts a comma-separated string: `"42,99"`. Parse in the handler:

```python
policy_ids = [int(x.strip()) for x in args.policy_ids.split(",")]
```

Wrap in `try/except ValueError` for non-integer input.

### Table Formatting (for `policy list --output text`)

Use simple string formatting — no external dependency:

```python
print(f"{'ID':<8} {'Name':<30} {'Rules':<6}")
print("-" * 44)
for p in policies:
    print(f"{p['id']:<8} {p['name']:<30} {len(p.get('rules', [])):<6}")
```

### Test Fixture Pattern

All new test classes follow the existing DI injection pattern. Example:

```python
class TestServerFirewallGetCommand:
    def test_get_firewall_text_output(self, capsys: pytest.CaptureFixture[str]) -> None:
        mock_client = MagicMock(spec=ScpApiClient)
        mock_client.find_server.return_value = 1
        mock_client.get_firewall.return_value = {
            "userPolicies": [{"id": 42, "name": "lockdown"}],
            "copiedPolicies": [],
            "ingressImplicitRule": "DROP",
            "egressImplicitRule": "ACCEPT",
            "consistent": True,
            "active": True,
        }
        args = argparse.Namespace(
            server="cupix001", mac="aa:bb:cc:dd:ee:ff",
            output="text", verbose=False, quiet=False, keyring=False,
        )
        cmd_server_firewall_get(args, client=mock_client)
        captured = capsys.readouterr()
        assert '"userPolicies"' in captured.out
```

### Commit Points

Per rule 02-commits, commit after each completed Red-Green-Refactor cycle:
- `feat(cli): add --output global flag to parse_args`
- `feat(api): add update_policy method to ScpApiClient`
- `feat(cli): add server firewall get/set argparse`
- `feat(cli): implement cmd_server_firewall_get handler`
- `feat(cli): implement cmd_server_firewall_set handler`
- `feat(cli): add policy list/create/update/delete argparse`
- `feat(cli): implement cmd_policy_list handler`
- `feat(cli): implement cmd_policy_create handler`
- `feat(cli): implement cmd_policy_update handler`
- `feat(cli): implement cmd_policy_delete handler`
- `test(cli): add full regression and quality gate validation`

---

## Current Status

- [x] Phase 1: Global `--output` flag (cycles 1.1–1.3)
- [x] Phase 2: `update_policy()` API method (cycles 2.1–2.2)
- [x] Phase 3a-Parse: `server firewall get/set` argparse (cycles 3a.1–3a.3)
- [x] Phase 3a-Get: `cmd_server_firewall_get()` handler (cycles 3a.4–3a.6)
- [x] Phase 3a-Set: `cmd_server_firewall_set()` handler (cycles 3a.7–3a.11)
- [x] Phase 3b-Parse: `policy list/create/update/delete` argparse (cycles 3b.1–3b.5)
- [x] Phase 3b-List: `cmd_policy_list()` handler (cycles 3b.6–3b.8)
- [x] Phase 3b-Create: `cmd_policy_create()` handler (cycles 3b.9–3b.12)
- [x] Phase 3b-Update: `cmd_policy_update()` handler (cycles 3b.13–3b.16)
- [x] Phase 3b-Delete: `cmd_policy_delete()` handler (cycles 3b.17–3b.20)
- [x] Phase 4: Import wiring + quality gate (cycles 4.1–4.2)

## Completion Log

| Phase | Commit | Tests | Notes |
|-------|--------|-------|-------|
| 1 | `49dffb9` | 151 | Global --output flag |
| 2 | `85bd9a8` | 153 | update_policy() API method |
| 3a-Parse | `3d184cf` | 156 | server firewall get/set argparse |
| 3a-Get | `7686d82` | 159 | cmd_server_firewall_get handler |
| 3a-Set | `0dd4498` | 164 | cmd_server_firewall_set handler |
| 3b-Parse | `b97a119` | 169 | policy list/create/update/delete argparse |
| 3b-List | `2fea167` | 172 | cmd_policy_list handler |
| 3b-Create | `7a782b4` | 176 | cmd_policy_create handler |
| 3b-Update | `30c7610` | 180 | cmd_policy_update handler |
| 3b-Delete | `8381068` | 184 | cmd_policy_delete handler |

**Completed Date**: 2026-04-17
**Total Tests Added**: 36 (from 148 to 184)
**Quality Gates**: All passed (mypy --strict, ruff check, ruff format)
**Review**: APPROVED — 7 findings (0 Critical, 0 High, 5 Medium, 2 Low), all non-blocking
