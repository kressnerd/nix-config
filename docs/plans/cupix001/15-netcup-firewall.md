← [Back to Index](00-index.md)

## Epic 15: Netcup External Firewall

**Goal**: Scripts and policy definitions for netcup Gen12 external firewall.

**Depends on**: Epic 1

### Story 15.1: Firewall Policy Definitions

#### Step 15.1.1: Red — Verify JSON schema for firewall policies

- **Test type**: shell check (JSON validation — not Nix)
- **What to test**: `python3 -c "import json; json.load(open('infra/firewall/cupix001-bootstrap.json'))"` exits non-zero if files don't exist yet
- **Verify**: `python3 -m json.tool infra/firewall/cupix001-bootstrap.json` → FAIL (file doesn't exist)
- **Expected**: FAIL

#### Step 15.1.2: Green — Create firewall policy JSON files

- **File**: `infra/firewall/cupix001-bootstrap.json`
- **What to implement**: JSON policy with rules: 22/tcp (temp), bootstrap-SSH-port/tcp, 443/tcp, 80/tcp, 3478/udp, WireGuard-port/udp. Default deny.
- **File**: `infra/firewall/cupix001-production.json`
- **What to implement**: JSON policy with rules: 443/tcp, 3478/udp, WireGuard-port/udp. Default deny. (80/tcp only if HTTP-01 needed.)
- **Verify**: `python3 -m json.tool infra/firewall/cupix001-bootstrap.json && python3 -m json.tool infra/firewall/cupix001-production.json`
- **Expected**: PASS

### Story 15.2: Firewall Management Script

#### Step 15.2.1: Red — Verify script argument parsing with offline test

- **Test type**: Python unit test (offline — no SCP API calls)
- **What to test**: Create `scripts/test_netcup_firewall.py` with tests for argument parsing (`--policy`, `--server`, `--lockdown`), policy file loading from JSON, and policy structure validation. These tests must not make any network calls.
- **Verify**: `python3 -m pytest scripts/test_netcup_firewall.py --co` → FAIL (test file doesn't exist yet)
- **Expected**: FAIL

#### Step 15.2.2: Green — Create netcup-firewall.py script with unit tests

- **File**: `scripts/netcup-firewall.py`
- **What to implement**: Python script that authenticates to SCP REST API (OIDC/Keycloak), creates/updates firewall policy from JSON, assigns to server, verifies. Support `--policy bootstrap|production|lockdown`, `--server cupix001`. Include `--lockdown` mode (DENY-all). Structure the code so authentication/API calls are injectable (for testability).
- **File**: `scripts/test_netcup_firewall.py`
- **What to implement**: Unit tests for offline logic: argument parsing, JSON policy loading, policy structure validation. Use `unittest.mock` for API calls.
- **Verify**: `python3 -m py_compile scripts/netcup-firewall.py && python3 -m pytest scripts/test_netcup_firewall.py`
- **Expected**: PASS

**Note**: Include `python3Packages.requests`, `python3Packages.pytest` in devShell dependencies.
