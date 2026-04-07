← [Back to Index](00-index.md)

## Epic 16: Automated Snapshot

**Goal**: Pre-deployment snapshot via SCP REST API.

**Depends on**: Epic 14 (deployment docs), Epic 15 (SCP API script base)

### Story 16.1: Snapshot Script

#### Step 16.1.1: Red — Verify snapshot function with offline test

- **Test type**: Python unit test (offline — no SCP API calls)
- **What to test**: Add snapshot-specific test to `scripts/test_netcup_firewall.py`: test that `create_snapshot(server_id, client)` calls the correct API endpoint path and handles success/failure responses correctly. Use `unittest.mock`.
- **Verify**: `python3 -m pytest scripts/test_netcup_firewall.py -k snapshot` → FAIL (snapshot function not yet implemented)
- **Expected**: FAIL

#### Step 16.1.2: Green — Implement snapshot function and tests

- **File**: `scripts/netcup-firewall.py` (extend) or `scripts/netcup-snapshot.py` (new)
- **What to implement**: Function to create server snapshot via SCP REST API, poll for completion, optional restore on failure. Integrate into deployment wrapper.
- **File**: `scripts/test_netcup_firewall.py` (extend)
- **What to implement**: Snapshot unit tests using `unittest.mock` for API calls
- **Verify**: `python3 -m py_compile scripts/netcup-firewall.py && python3 -m pytest scripts/test_netcup_firewall.py`
- **Expected**: PASS
