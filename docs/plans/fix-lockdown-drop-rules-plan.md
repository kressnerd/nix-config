# Fix Lockdown Command — Explicit DROP Rules

## Status: COMPLETED

## Goal

Fix the `lockdown` command so it creates a firewall policy with explicit DROP rules instead of an empty rules list. The SCP API defaults to `ACCEPT_ALL` when no rules are present, making the current lockdown completely ineffective.

## Business Context

The lockdown command is a security kill switch intended to block all network traffic to a server during emergencies. The current implementation passes an empty rules list `[]`, which the SCP API interprets as "no rules → ACCEPT_ALL", the opposite of the intended behavior. This is a critical security defect.

## Acceptance Criteria

1. `_find_or_create_lockdown_policy()` passes explicit DROP rules for INGRESS TCP, UDP, ICMP, ICMPv6 to `client.create_policy()` instead of `[]`
2. `create_policy()` and `update_policy()` no longer convert empty lists `[]` to `UNSET` — the `if fw_rules` guard is changed to `if fw_rules is not None`
3. `infra/firewall/lockdown.json` contains the four explicit DROP rules
4. All existing tests for other commands remain passing
5. `infra/firewall/README.md` no longer claims "empty rules = DROP ALL"

## Technical Analysis

### Root Cause Chain

1. [`_find_or_create_lockdown_policy()`](scripts/netcup_firewall.py:1294) calls `client.create_policy(user_id, lockdown_name, [])` at [line 1324](scripts/netcup_firewall.py:1324)
2. [`ScpApi.create_policy()`](scripts/netcup_firewall.py:655) converts `[]` to `UNSET` at [line 682](scripts/netcup_firewall.py:682): `fw_rules if fw_rules else UNSET`
3. `FirewallPolicySave(name=..., rules=UNSET)` omits `rules` from the JSON body
4. SCP API receives no `rules` field → defaults `ingressImplicitRule = ACCEPT_ALL`

### Fix Design

**Lockdown rules**: Define four explicit DROP-all rules covering all protocol types the API supports:

```python
LOCKDOWN_RULES: list[dict[str, str]] = [
    {"direction": "INGRESS", "protocol": "TCP",    "sourceIp": "", "destinationPort": "", "action": "DROP"},
    {"direction": "INGRESS", "protocol": "UDP",    "sourceIp": "", "destinationPort": "", "action": "DROP"},
    {"direction": "INGRESS", "protocol": "ICMP",   "sourceIp": "", "destinationPort": "", "action": "DROP"},
    {"direction": "INGRESS", "protocol": "ICMPv6", "sourceIp": "", "destinationPort": "", "action": "DROP"},
]
```

Empty `sourceIp` → `sources = UNSET` → any source. Empty `destinationPort` → `destination_ports = UNSET` → any port. This matches how [`_legacy_rule_to_firewall_rule()`](scripts/netcup_firewall.py:616) handles these fields.

**`create_policy` / `update_policy` guard fix**: Change `if fw_rules` to `if fw_rules is not None` at [line 682](scripts/netcup_firewall.py:682) and [line 719](scripts/netcup_firewall.py:719) so that an intentionally empty list `[]` is sent as `rules: []` in the API body instead of being silently converted to `UNSET`.

### Affected Files

| File | Change |
|------|--------|
| [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py) | Add `LOCKDOWN_RULES` constant; update `_find_or_create_lockdown_policy()`; fix `create_policy()` and `update_policy()` guards |
| [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py) | Update 4 tests; add 1 new test |
| [`infra/firewall/lockdown.json`](infra/firewall/lockdown.json) | Replace empty rules with explicit DROP rules |
| [`infra/firewall/README.md`](infra/firewall/README.md) | Remove incorrect "empty rules = DROP ALL" claim |

### Tests Requiring Changes

| Test | Location | Current Assertion | New Assertion |
|------|----------|-------------------|---------------|
| `test_lockdown_creates_empty_policy` | [line 1582](scripts/tests/test_netcup_firewall.py:1582) | `create_policy(42, "lockdown-cupix001", [])` | `create_policy(42, "lockdown-cupix001", LOCKDOWN_RULES)` |
| `test_full_backup_lockdown_restore_cycle` | [line 2193](scripts/tests/test_netcup_firewall.py:2193) | `create_policy(42, "lockdown-cupix001", [])` at [line 2266](scripts/tests/test_netcup_firewall.py:2266) | `create_policy(42, "lockdown-cupix001", LOCKDOWN_RULES)` |
| `test_load_lockdown_json_from_infra` | [line 3222](scripts/tests/test_netcup_firewall.py:3222) | `result["rules"] == []` | `len(result["rules"]) == 4` + each rule has `action == "DROP"` |
| Mock setup `_make_mock_setup` | [line 1537](scripts/tests/test_netcup_firewall.py:1537) | `create_policy` returns `"rules": []` | `create_policy` returns `"rules": LOCKDOWN_RULES` |

### Reuse Path Consideration

When [`_find_or_create_lockdown_policy()`](scripts/netcup_firewall.py:1294) finds an existing policy at [line 1314](scripts/netcup_firewall.py:1314), it returns it as-is without checking its rules. This is acceptable for now — fixing old policies is out of scope. The existing policy was presumably created by a prior version of the tool. If the user wants updated rules, they can delete and re-create.

## Implementation Phases

### Phase 0: Validation Strategy

- **Syntax validation**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v`
- **Lint**: `cd scripts && ruff check netcup_firewall.py tests/test_netcup_firewall.py`
- **Type check**: `cd scripts && mypy --strict netcup_firewall.py`
- **Format**: `cd scripts && ruff format --check .`
- **Rollback**: `git revert` — all changes are in-repo, no deployed state changes

### Phase 1: Fix `create_policy` / `update_policy` Empty-List Guard

This is the latent bug fix. Fixing it first means subsequent phases work correctly even if someone passes `[]`.

#### Cycle 1.1 — Red: Test `create_policy` preserves empty list

- **File**: [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py)
- **Action**: Add a new test in the `TestScpApi` class asserting that `create_policy(user_id, name, [])` calls `FirewallPolicySave(name=name, rules=[])` not `rules=UNSET`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestScpApi::test_create_policy_empty_list_sends_empty_rules -v` → FAIL

#### Cycle 1.2 — Green: Fix `create_policy` guard

- **File**: [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py) line 682
- **Action**: Change `fw_rules if fw_rules else UNSET` → `fw_rules if fw_rules is not None else UNSET`
- **Verify**: Same test → PASS

#### Cycle 1.3 — Red: Test `update_policy` preserves empty list

- **File**: [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py)
- **Action**: Add a new test in the `TestScpApi` class asserting that `update_policy(user_id, policy_id, name, [])` calls `FirewallPolicySave(name=name, rules=[])` not `rules=UNSET`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestScpApi::test_update_policy_empty_list_sends_empty_rules -v` → FAIL

#### Cycle 1.4 — Green: Fix `update_policy` guard

- **File**: [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py) line 719
- **Action**: Change `fw_rules if fw_rules else UNSET` → `fw_rules if fw_rules is not None else UNSET`
- **Verify**: Same test → PASS

#### Cycle 1.5 — Refactor: Run full test suite

- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v` → all PASS

### Phase 2: Add `LOCKDOWN_RULES` Constant and Fix `_find_or_create_lockdown_policy`

#### Cycle 2.1 — Red: Update lockdown policy creation test

- **File**: [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py)
- **Action**: Rename `test_lockdown_creates_empty_policy` → `test_lockdown_creates_drop_all_policy`. Change assertion from `create_policy(42, "lockdown-cupix001", [])` to assert that the third argument is a list of 4 dicts each with `"action": "DROP"` covering TCP, UDP, ICMP, ICMPv6
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestLockdownCommand::test_lockdown_creates_drop_all_policy -v` → FAIL

#### Cycle 2.2 — Green: Add constant and fix `_find_or_create_lockdown_policy`

- **File**: [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py)
- **Action**:
  1. Define module-level constant `LOCKDOWN_RULES` with the four DROP rules
  2. Change [line 1324](scripts/netcup_firewall.py:1324) from `client.create_policy(user_id, lockdown_name, [])` → `client.create_policy(user_id, lockdown_name, LOCKDOWN_RULES)`
  3. Update docstring at [line 1301](scripts/netcup_firewall.py:1301) to reflect explicit DROP rules instead of "no rules"
  4. Update log message at [line 1322](scripts/netcup_firewall.py:1322)
- **Verify**: Same test → PASS

#### Cycle 2.3 — Refactor: Update `_make_mock_setup` return values and related mock data

- **File**: [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py)
- **Action**: Update `_make_mock_setup` in `TestLockdownCommand` at [line 1537](scripts/tests/test_netcup_firewall.py:1537): change `create_policy.return_value` and `get_firewall.return_value` to include the four DROP rules in the `rules` field instead of `[]`
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestLockdownCommand -v` → all PASS

### Phase 3: Fix Integration Test

#### Cycle 3.1 — Red/Green: Update workflow integration test

- **File**: [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py)
- **Action**: In [`test_full_backup_lockdown_restore_cycle`](scripts/tests/test_netcup_firewall.py:2193):
  1. Change `create_policy.return_value` at [line 2248](scripts/tests/test_netcup_firewall.py:2248) to include DROP rules
  2. Change assertion at [line 2266](scripts/tests/test_netcup_firewall.py:2266) from `create_policy(42, "lockdown-cupix001", [])` to assert the four DROP rules
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestWorkflow -v` → PASS

### Phase 4: Update `infra/firewall/lockdown.json` and its test

#### Cycle 4.1 — Red: Update lockdown JSON validation test

- **File**: [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py)
- **Action**: In [`test_load_lockdown_json_from_infra`](scripts/tests/test_netcup_firewall.py:3222):
  1. Change `result["rules"] == []` → `len(result["rules"]) == 4`
  2. Assert each rule has `"action": "DROP"` and `"direction": "INGRESS"`
  3. Assert protocols cover TCP, UDP, ICMP, ICMPv6
- **Verify**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py::TestPolicyFileOperations::test_load_lockdown_json_from_infra -v` → FAIL

#### Cycle 4.2 — Green: Update `lockdown.json`

- **File**: [`infra/firewall/lockdown.json`](infra/firewall/lockdown.json)
- **Action**: Replace contents with:
  ```json
  {
    "name": "lockdown",
    "description": "Block all inbound traffic via explicit DROP rules",
    "rules": [
      {"direction": "INGRESS", "protocol": "TCP",    "sourceIp": "", "destinationPort": "", "action": "DROP"},
      {"direction": "INGRESS", "protocol": "UDP",    "sourceIp": "", "destinationPort": "", "action": "DROP"},
      {"direction": "INGRESS", "protocol": "ICMP",   "sourceIp": "", "destinationPort": "", "action": "DROP"},
      {"direction": "INGRESS", "protocol": "ICMPv6", "sourceIp": "", "destinationPort": "", "action": "DROP"}
    ]
  }
  ```
- **Verify**: Same test → PASS

### Phase 5: Update Documentation

#### Step 5.1 — Update `infra/firewall/README.md`

- **File**: [`infra/firewall/README.md`](infra/firewall/README.md)
- **Action**:
  1. Change table description for `lockdown.json` from "Block all traffic (implicit DROP ALL)" → "Block all inbound traffic via explicit DROP rules"
  2. Remove or correct the limitation line "Empty `rules` array = DROP ALL (used by lockdown policy)" at line 45
  3. Add note: "Empty `rules` array results in API default ACCEPT_ALL — always use explicit DROP rules"

### Phase 6: Final Validation

- [x] `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v` → all PASS
- [x] `cd scripts && ruff check .` → zero violations
- [x] `cd scripts && mypy --strict netcup_firewall.py` → PASS
- [x] `cd scripts && ruff format --check .` → PASS
- [x] Manual review: no other callers pass `[]` to `create_policy` or `update_policy` expecting DROP behavior

## Completion Log

_To be filled during implementation._

## Completion Summary

- **Completed Date**: 2026-04-23
- **Total Duration**: ~2 hours
- **Deviations**:
  - Phase 1 and Phase 2 were each executed as combined Red+Green subtasks rather than separate Red/Green subtasks, reducing overhead while maintaining TDD discipline
  - Added Phase for review finding fixes: stale policy reuse reconciliation (F-001), guard simplification (F-002), documentation fixes (F-003/F-004), test coverage improvement (F-005), redundant import cleanup (F-007), ICMP field cleanup (F-006)
- **Lessons Learned**:
  - Python's truthiness of empty lists (`[]` is falsy) can silently convert intended values to sentinel values like `UNSET` — always use explicit identity checks (`is not None`) or unconditional assignment when the type is guaranteed
  - Security-critical "reuse" paths must be validated: when a function finds an existing resource by name, it must verify the resource's state matches expectations, not just return it blindly
  - SCP API does NOT default to DROP when rules are absent — it defaults to ACCEPT_ALL. Always verify API default behavior empirically rather than assuming
  - Legacy dict formats that include optional fields as empty strings (e.g., `"destinationPort": ""`) should omit those fields entirely when the conversion layer handles missing keys gracefully
  - When fixing a security function, update ALL artifacts: production code, tests, JSON fixtures, README files, docstrings — stale documentation is a security risk because operators may rely on it
