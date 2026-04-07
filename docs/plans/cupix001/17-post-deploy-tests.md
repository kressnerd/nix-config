← [Back to Index](00-index.md)

## Epic 17: Post-Deploy Tests

**Goal**: pytest-testinfra suite for post-deployment validation.

**Depends on**: Epic 7 (Caddy running), Epic 13 (colmena for deployment)

### Story 17.1: Testinfra Setup

#### Step 17.1.1: Red — Verify pytest is not yet in devShell

- **Test type**: shell check
- **What to test**: Before adding testinfra, confirm `nix develop --command pytest --version` fails (exits non-zero) — proving the Red state
- **Verify**: `nix develop --command pytest --version` → FAIL (pytest not in devShell)
- **Expected**: FAIL

#### Step 17.1.2: Green — Add testinfra to devShell

- **File**: `shell.nix` or `flake.nix` devShell
- **What to implement**: Add `python3Packages.pytest`, `python3Packages.pytest-testinfra`, `python3Packages.requests` to devShell
- **Verify**: `nix develop --command pytest --version`
- **Expected**: PASS

### Story 17.2: Post-Deploy Test Suite

#### Step 17.2.1: Green — Create testinfra test file

- **File**: `tests/deploy/test_cupix001.py`
- **What to implement**: Tests for: WireGuard wg0 exists with correct IP, Caddy service running, ports 443/3478 listening, no gcc/git/make in PATH, firewall active, SSH password auth disabled, `/persist` directories exist, security headers in Caddy response, SSH host key fingerprint matches, ACME cert present, WireGuard tunnel reachable (ping homelab side), DNS resolution works (`host google.com` or equivalent resolves successfully — spec §15 Layer 3: "DNS resolution works")
- **Verify**: `pytest --co tests/deploy/test_cupix001.py` (collect-only, no execution)
- **Expected**: PASS (tests collected but not run — no live host)
