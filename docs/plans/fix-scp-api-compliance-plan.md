# Fix SCP API Compliance in netcup_firewall.py

## Business Context

The `scripts/netcup_firewall.py` CLI tool produces 422 errors when calling the Netcup SCP REST API firewall endpoints. The root cause is that three functions send or parse payloads that violate the OpenAPI schema (`ServerFirewallSave` for PUT, `ServerFirewall` for GET responses). Fixing these is required for the `lockdown`, `restore`, `ssh-open`, and `ssh-close` commands to work.

## Acceptance Criteria

- [x] `_get_current_policy_ids()` returns `list[int]` extracted from `FirewallPolicy` objects (dicts with `id` key) in the GET response
- [x] `set_firewall()` accepts `policy_ids: list[int]`, internally wraps each as `{"id": n}`, always includes `"copiedPolicies": []`
- [x] `_reassign_firewall_interfaces()` extracts integer IDs from backup `userPolicies` (which are full policy objects)
- [x] All 130+ existing tests pass after changes
- [x] All test mocks use realistic API response shapes matching the OpenAPI spec
- [x] Quality gates pass: `mypy --strict`, `ruff check`, `ruff format --check`

## Technical Analysis

### API Schema (from OpenAPI spec)

**GET `/servers/{id}/interfaces/{mac}/firewall`** returns `ServerFirewall`:

```json
{
  "userPolicies": [{"id": 42, "name": "my-policy", "rules": [...]}],
  "copiedPolicies": [],
  "ingressImplicitRule": "DROP",
  "egressImplicitRule": "DROP",
  "consistent": true,
  "active": true
}
```

`userPolicies` contains full `FirewallPolicy` objects — not plain integers.

**PUT `/servers/{id}/interfaces/{mac}/firewall`** expects `ServerFirewallSave`:

```json
{
  "userPolicies": [{"id": 42}],
  "copiedPolicies": []
}
```

`userPolicies` contains `IdentifierInt` objects (`{"id": n}`), and `copiedPolicies` is **required** (even if empty).

### Current Code vs. Required

| Location | Current Behavior | Required Behavior |
|---|---|---|
| [`_get_current_policy_ids()`](scripts/netcup_firewall.py:750) | `list(firewall_state.get("userPolicies", []))` — returns list of dicts | Extract `["id"]` from each policy object → `list[int]` |
| [`set_firewall()`](scripts/netcup_firewall.py:450) | Accepts raw `payload: dict` — callers pass `{"userPolicies": [42]}` | Accept `policy_ids: list[int]`, build `{"userPolicies": [{"id": n}], "copiedPolicies": []}` internally |
| [`_reassign_firewall_interfaces()`](scripts/netcup_firewall.py:1010) | Reads backup `userPolicies` as plain ints | Extract `["id"]` from policy objects in backup |
| [`_apply_lockdown_to_interfaces()`](scripts/netcup_firewall.py:867) | `{"userPolicies": [lockdown_policy["id"]]}` | Will just pass `[lockdown_policy["id"]]` to new `set_firewall()` |
| [`_find_or_create_ssh_policy()`](scripts/netcup_firewall.py:833) | `{"userPolicies": new_ids}` | Will just pass `new_ids` to new `set_firewall()` |
| [`cmd_ssh_open()`](scripts/netcup_firewall.py:1231) | `{"userPolicies": new_ids}` | Will just pass `new_ids` to new `set_firewall()` |
| [`cmd_ssh_close()`](scripts/netcup_firewall.py:1294) | `{"userPolicies": new_ids}` | Will just pass `new_ids` to new `set_firewall()` |

### Design Decision: Option A (Recommended)

Change `set_firewall()` signature from `payload: dict[str, Any]` to `policy_ids: list[int]`. The method internally builds the `ServerFirewallSave` payload:

```python
def set_firewall(self, server_id: int, mac: str, policy_ids: list[int]) -> str:
    payload = {
        "userPolicies": [{"id": pid} for pid in policy_ids],
        "copiedPolicies": [],
    }
    resp = self._put(f"/servers/{server_id}/interfaces/{mac}/firewall", payload)
    return resp.json()["uuid"]
```

**Rationale**: DRY + Single Responsibility. One place knows the API payload format. All callers keep passing plain `list[int]`. No caller needs to know about `IdentifierInt` or `copiedPolicies`.

### Impact on Backup Format

The backup file stores raw GET responses in `interfaces[].firewall`. This means backup `userPolicies` will contain full policy objects (dicts), not plain integers. The `_reassign_firewall_interfaces()` function must extract `["id"]` from these objects.

However, we must handle **both old and new backup formats** gracefully: old backups have `userPolicies: [1, 2]` (ints), new backups will have `userPolicies: [{"id": 1, ...}, {"id": 2, ...}]` (dicts). A simple type check handles this.

## Phase 0: Validation Strategy

### Validation Commands

- **Syntax + type check**: `cd scripts && mypy --strict netcup_firewall.py`
- **Tests**: `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v`
- **Lint**: `cd scripts && ruff check .`
- **Format**: `cd scripts && ruff format --check .`

### Rollback Path

All changes are in two files (`scripts/netcup_firewall.py`, `scripts/tests/test_netcup_firewall.py`). Revert with `git checkout -- scripts/`.

### Risk Assessment

| Category | Risk | Mitigation |
|---|---|---|
| Backup compatibility | Old backups have int userPolicies, new ones have dict | Type-check each element in `_reassign_firewall_interfaces()` |
| Test count regression | Signature change breaks many tests | Cycle 4 updates all test mocks systematically |
| API correctness | Wrong payload still causes 422 | Manual verification against OpenAPI spec values |

## Implementation Phases

### Phase 1: Fix `_get_current_policy_ids()` — extract IDs from policy objects

**Goal**: The GET response returns `userPolicies` as full `FirewallPolicy` objects. This function must extract the `id` field from each.

#### Cycle 1.1 — Red: test expects ID extraction from policy objects

- [x] **Step 1**: In `TestGetCurrentPolicyIds`, update [`test_returns_policy_ids_from_firewall()`](scripts/tests/test_netcup_firewall.py:1682) mock to return realistic API shape:
  ```python
  client.get_firewall.return_value = {
      "userPolicies": [
          {"id": 42, "name": "p1", "rules": []},
          {"id": 99, "name": "p2", "rules": []},
      ],
      ...
  }
  ```
  Keep assertion: `assert result == [42, 99]`
- [x] **Step 2**: Run tests → FAIL (current code returns `[{"id": 42, ...}, {"id": 99, ...}]` instead of `[42, 99]`)

#### Cycle 1.2 — Green: implement ID extraction

- [x] **Step 3**: In [`_get_current_policy_ids()`](scripts/netcup_firewall.py:750), change line 764 from:
  ```python
  return list(firewall_state.get("userPolicies", []))
  ```
  to:
  ```python
  return [p["id"] for p in firewall_state.get("userPolicies", [])]
  ```
- [x] **Step 4**: Run tests → PASS
- [x] **Step 5**: Also update [`test_returns_empty_list_when_no_policies()`](scripts/tests/test_netcup_firewall.py:1696) mock to use `[]` (unchanged, already correct — empty list works with both old and new)

#### Cycle 1.3 — Refactor (if needed)

- [x] **Step 6**: Verify `mypy --strict`, `ruff check`, `ruff format --check` pass

### Phase 2: Fix `set_firewall()` — accept `policy_ids: list[int]`, build compliant payload

**Goal**: Change the `ScpApiClient.set_firewall()` signature so it accepts a plain list of integer IDs and internally constructs the `ServerFirewallSave` payload with `IdentifierInt` objects and required `copiedPolicies`.

#### Cycle 2.1 — Red: test expects new signature

- [x] **Step 7**: In [`test_set_firewall()`](scripts/tests/test_netcup_firewall.py:409), change the call from:
  ```python
  result = client.set_firewall(12345, "aa:bb:cc:dd:ee:ff", {"userPolicies": [99]})
  ```
  to:
  ```python
  result = client.set_firewall(12345, "aa:bb:cc:dd:ee:ff", [99])
  ```
  Add assertion that the PUT payload sent to the session contains `{"userPolicies": [{"id": 99}], "copiedPolicies": []}`:
  ```python
  sent_payload = mock_put.call_args[1]["json"]
  assert sent_payload == {"userPolicies": [{"id": 99}], "copiedPolicies": []}
  ```
- [x] **Step 8**: Run tests → FAIL (signature mismatch)

#### Cycle 2.2 — Green: change `set_firewall()` signature and body

- [x] **Step 9**: In [`set_firewall()`](scripts/netcup_firewall.py:450), change:
  ```python
  def set_firewall(self, server_id: int, mac: str, policy_ids: list[int]) -> str:
      payload = {
          "userPolicies": [{"id": pid} for pid in policy_ids],
          "copiedPolicies": [],
      }
      resp = self._put(
          f"/servers/{server_id}/interfaces/{mac}/firewall", payload
      )
      return resp.json()["uuid"]
  ```
- [x] **Step 10**: Run `test_set_firewall` → PASS

#### Cycle 2.3 — Update all callers to pass `list[int]` instead of `dict`

- [x] **Step 11**: Update [`_apply_lockdown_to_interfaces()`](scripts/netcup_firewall.py:867):
  ```python
  # Before: client.set_firewall(server_id, mac, {"userPolicies": [lockdown_policy["id"]]})
  # After:
  client.set_firewall(server_id, mac, [lockdown_policy["id"]])
  ```
- [x] **Step 12**: Update [`_find_or_create_ssh_policy()`](scripts/netcup_firewall.py:833):
  ```python
  # Before: client.set_firewall(server_id, mac, {"userPolicies": new_ids})
  # After:
  client.set_firewall(server_id, mac, new_ids)
  ```
- [x] **Step 13**: Update [`cmd_ssh_open()`](scripts/netcup_firewall.py:1231):
  ```python
  # Before: client.set_firewall(server_id, mac, {"userPolicies": new_ids})
  # After:
  client.set_firewall(server_id, mac, new_ids)
  ```
- [x] **Step 14**: Update [`cmd_ssh_close()`](scripts/netcup_firewall.py:1294):
  ```python
  # Before: client.set_firewall(server_id, mac, {"userPolicies": new_ids})
  # After:
  client.set_firewall(server_id, mac, new_ids)
  ```
- [x] **Step 15**: Update [`_reassign_firewall_interfaces()`](scripts/netcup_firewall.py:1014):
  ```python
  # Before: client.set_firewall(server_id, mac, {"userPolicies": new_policy_ids})
  # After:
  client.set_firewall(server_id, mac, new_policy_ids)
  ```
- [x] **Step 16**: Run `mypy --strict` → verify no type errors from callers
- [x] **Step 17**: Run full test suite → expect failures in tests that assert old `set_firewall` call signature (these are fixed in Phase 4)

### Phase 3: Fix `_reassign_firewall_interfaces()` — extract IDs from backup policy objects

**Goal**: The backup file stores raw GET responses, so `userPolicies` in the backup contains full policy objects (dicts). Handle both old format (ints) and new format (dicts).

#### Cycle 3.1 — Red: test uses realistic backup with policy objects

- [x] **Step 18**: In [`TestRestoreCommand._make_backup_file()`](scripts/tests/test_netcup_firewall.py:963), update the backup fixture `interfaces[0].firewall.userPolicies` from `[1]` to:
  ```python
  "userPolicies": [{"id": 1, "name": "my-policy", "rules": [...]}]
  ```
  This matches what `_gather_interface_firewall_state()` stores (raw GET response).
- [x] **Step 19**: Run restore tests → FAIL (code tries `id_map.get({"id": 1, ...})` — unhashable type)

#### Cycle 3.2 — Green: extract IDs with backward compatibility

- [x] **Step 20**: In [`_reassign_firewall_interfaces()`](scripts/netcup_firewall.py:1010), change line 1011 from:
  ```python
  old_policy_ids = iface_backup.get("firewall", {}).get("userPolicies", [])
  ```
  to:
  ```python
  raw_policies = iface_backup.get("firewall", {}).get("userPolicies", [])
  old_policy_ids = [
      p["id"] if isinstance(p, dict) else p for p in raw_policies
  ]
  ```
- [x] **Step 21**: Run restore tests → PASS

#### Cycle 3.3 — Refactor

- [x] **Step 22**: Verify `mypy --strict`, `ruff check`, `ruff format --check` pass

### Phase 4: Update all test mocks to match real API response shapes

**Goal**: Systematically fix every test that uses incorrect mock data. After this phase, all 130+ tests pass and mock data matches the OpenAPI spec.

#### Step 23: Fix GET firewall mocks (userPolicies → policy objects)

Update all `mock_client.get_firewall.return_value` dicts where `userPolicies` contains plain ints to contain policy objects instead. Affected test classes/methods:

| Test Class | Method | Current mock `userPolicies` | New mock `userPolicies` |
|---|---|---|---|
| `TestGetCurrentPolicyIds` | all 3 tests | Already fixed in Phase 1 | — |
| `TestBackupCommand` | [`test_backup_includes_firewall_state()`](scripts/tests/test_netcup_firewall.py:589) | `[1, 2]` | `[{"id": 1, ...}, {"id": 2, ...}]` |
| `TestLockdownCommand` | [`test_lockdown_verifies_state()`](scripts/tests/test_netcup_firewall.py:866) | `{"active": True}` | OK (no userPolicies accessed) |
| `TestWorkflow` | [`test_full_backup_lockdown_restore_cycle()`](scripts/tests/test_netcup_firewall.py:1386) | `[1]` | `[{"id": 1, "name": "production", "rules": [...]}]` |
| `TestSshOpenCommand` | multiple | `[50]`, `[777]`, `[]` | `[{"id": 50, ...}]`, `[{"id": 777, ...}]`, `[]` |
| `TestSshCloseCommand` | multiple | `[50, 777]`, `[777]`, `[50]` | `[{"id": 50, ...}, {"id": 777, ...}]`, etc. |
| `TestFindOrCreateSshPolicy` | multiple | `[555, 50]`, `[50]` | `[{"id": 555, ...}, {"id": 50, ...}]`, etc. |

#### Step 24: Fix `set_firewall` call assertions

Update all `mock_client.set_firewall.assert_called_*` assertions that check `{"userPolicies": [...]}` dict argument to check `list[int]` argument instead.

Affected assertions (example pattern):

```python
# Before:
mock_client.set_firewall.assert_called_once_with(
    12345, "aa:bb:cc:dd:ee:ff", {"userPolicies": [99]}
)
# After:
mock_client.set_firewall.assert_called_once_with(
    12345, "aa:bb:cc:dd:ee:ff", [99]
)
```

Affected locations:

| Test Class | Method | Line (approx) |
|---|---|---|
| `TestLockdownCommand` | `test_lockdown_assigns_policy_to_interface` | 843 |
| `TestRestoreCommand` | `test_restore_assigns_policies_to_interfaces` | 1163 |
| `TestFindOrCreateSshPolicy` | `test_stale_policy_unassigned_before_deletion` | 1824 |
| `TestSshOpenCommand` | multiple | various |
| `TestSshCloseCommand` | multiple | various |

#### Step 25: Run full test suite and quality gates

- [x] `cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v` → all 132 PASS
- [x] `cd scripts && mypy --strict netcup_firewall.py` → PASS
- [x] `cd scripts && ruff check .` → PASS
- [x] `cd scripts && ruff format --check .` → PASS

## Validation Strategy

### Per-Cycle Validation

After each Green step:
```bash
cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v --tb=short
```

### Final Validation

```bash
cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v
cd scripts && mypy --strict netcup_firewall.py
cd scripts && ruff check .
cd scripts && ruff format --check .
```

### Manual Verification (post-deploy)

After deploying, run `ssh-open` and `ssh-close` against the real SCP API and verify no 422 errors.

## Current Status

- [x] Phase 0: Validation Strategy — DEFINED
- [x] Phase 1: Fix `_get_current_policy_ids()` (Cycles 1.1–1.3)
- [x] Phase 2: Fix `set_firewall()` signature + all callers (Cycles 2.1–2.3)
- [x] Phase 3: Fix `_reassign_firewall_interfaces()` (Cycles 3.1–3.3)
- [x] Phase 4: Update all test mocks (Steps 23–25)

**All phases complete. Implementation finished 2026-04-13.**

## Completion Log

- **2026-04-13**: All four phases implemented and validated. 132 tests pass. `mypy --strict`, `ruff check`, and `ruff format --check` all clean.
