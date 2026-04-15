# User Story: CUP-018

**Title:** Restructure netcup SCP CLI as full OpenAPI-backed client  
**Status:** Backlog  
**Priority:** High  
**Labels:** cli, netcup, firewall, api-client, openapi

---

## Story Description

As a **Infrastructure Engineer managing netcup VPS infrastructure**,  
I want **a restructured `netcup-scp` CLI that auto-generates its API client from the SCP OpenAPI spec and separates server-specific firewall operations from user-level policy management**,  
To **interact with the full SCP API more reliably than raw cURL, with transparent OIDC authentication, input validation, and clean separation between server and policy concerns**.

**Consequence Analysis:**  
If this story is not implemented, the hand-crafted [`ScpApiClient`](scripts/netcup_firewall.py:450) covers only a fraction of SCP API endpoints, mixes server-state and user-policy operations in single commands, and requires manual `Authorization: Bearer ...` header juggling for any endpoint not yet wrapped — making firewall automation fragile and error-prone.

**Story Owner:** Dan, Infrastructure/DevOps

---

## Affected Components Checklist

- **System Services**: No system services impacted (operator CLI tool only)
- **NixOS Modules**: No NixOS modules involved; Nix packaging wraps the CLI via `pkgs/` / `flake.nix`
- **Home Manager Features**: No Home Manager changes
- **Overlays/Packages**: Nix package definition for the CLI (`pkgs/netcup-scp/`) will be updated when client is generated
- **Host Configurations**: No host configs changed
- **Labels**: `cli`, `netcup`, `firewall`, `api-client`, `openapi` ✓
- **Python CLI Tools**: [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py) and [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py) are the primary targets

---

## Context and Scope

**Context:**

The existing [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py) was built iteratively to fix specific operational problems (kill-switch, SSH access, backup/restore). Its `ScpApiClient` is hand-crafted and covers only the server-interface firewall endpoints (`/api/v1/servers/{serverId}/interfaces/{mac}/firewall`). The netcup SCP API also exposes:

- `GET /api/v1/openapi` — full OpenAPI 3.0.3 machine-readable spec
- `POST /api/v1/openapi/mcp` — Model Context Protocol endpoint
- `GET/POST/PUT/DELETE /api/v1/users/{userId}/firewall-policies` — reusable user-owned policy CRUD

Current commands mix concerns: `backup`/`restore` handle both server firewall state and user policy objects in a single operation; `lockdown`/`ssh-open`/`ssh-close` manipulate server interfaces but create/manage user policies as side effects. This conflation makes the code harder to reason about and prevents clean independent operation.

The restructuring proceeds in four sequential phases:

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 | `openapi` command group: download spec, explore MCP endpoint | ✅ Completed |
| 2 | Generated Python API client from the downloaded OpenAPI spec | ✅ Completed |
| 3a | `server firewall` command group: get/set per-interface firewall state | Not Started |
| 3b | `policy` command group: full CRUD for user-owned firewall policies | Not Started |

**Out of Scope:**

- Changes to NixOS host configurations (`hosts/cupix001/`)
- Changes to existing OIDC auth flow (`ScpAuth`) — reused as-is
- Migration of `infra/firewall/*.json` policy definitions — no format change
- Removal of existing `backup`, `restore`, `lockdown`, `ssh-open`, `ssh-close` commands during this story (deprecated later)
- `nix-darwin` or Home Manager integration

---

## Acceptance Criteria (BDD/Gherkin)

### Phase 1: OpenAPI Spec Discovery

#### Scenario 1.1: Download and save the SCP OpenAPI spec

**Given** the operator is authenticated (valid OIDC token in `~/.config/netcup-scp/credentials.json`)  
**When** they run `netcup-scp openapi download --output /tmp/scp-openapi.json`  
**Then** the tool performs `GET /api/v1/openapi` with the bearer token  
**And** saves the response body as valid JSON to `/tmp/scp-openapi.json`  
**And** prints `Saved OpenAPI spec to /tmp/scp-openapi.json` to stdout  
**And** exits with code `0`

#### Scenario 1.2: Download fails when unauthenticated

**Given** the operator has no valid credentials (credentials file absent or refresh token expired)  
**When** they run `netcup-scp openapi download --output /tmp/scp-openapi.json`  
**Then** the tool prints an authentication error message to stderr  
**And** exits with code `1`  
**And** does NOT create or overwrite the output file

#### Scenario 1.3: Explore the MCP endpoint

**Given** the operator is authenticated  
**When** they run `netcup-scp openapi mcp --message "list available tools"`  
**Then** the tool performs `POST /api/v1/openapi/mcp` with the bearer token and the message body  
**And** prints the MCP response JSON to stdout  
**And** exits with code `0`

#### Scenario 1.4: Download output path is not writable

**Given** the operator is authenticated  
**When** they run `netcup-scp openapi download --output /root/protected/spec.json`  
**And** the output directory does not exist or is not writable  
**Then** the tool prints a permission error to stderr  
**And** exits with code `1`

---

### Phase 2: Generated Python API Client

#### Scenario 2.1: Generate client from a local OpenAPI spec file

**Given** a valid OpenAPI 3.0.3 spec file exists at `scripts/scp-openapi.json`  
**When** the developer runs the code-generation step (e.g., `openapi-python-client generate --path scripts/scp-openapi.json --output-path scripts/scp_client/`)  
**Then** a Python package is created at `scripts/scp_client/`  
**And** the package contains typed model classes for all schemas defined in the spec (including `ServerFirewall`, `ServerFirewallSave`, `FirewallPolicy`, `IdentifierInt`)  
**And** the package contains API client methods for all endpoints defined in the spec

#### Scenario 2.2: Generated client covers server firewall endpoints

**Given** the generated client package `scripts/scp_client/` exists  
**When** a developer imports `from scp_client.api.servers import get_server_interface_firewall`  
**Then** the import succeeds without error  
**And** the function signature accepts `server_id: str`, `mac: str`, and an authenticated `httpx.Client`  
**And** the return type is `ServerFirewall`

#### Scenario 2.3: Generated client covers user policy endpoints

**Given** the generated client package `scripts/scp_client/` exists  
**When** a developer imports `from scp_client.api.users import list_user_firewall_policies`  
**Then** the import succeeds without error  
**And** the function signature accepts `user_id: str` and an authenticated `httpx.Client`  
**And** the return type is `list[FirewallPolicy]`

#### Scenario 2.4: Existing `mypy --strict` gate passes after client generation

**Given** the generated client has been added to `scripts/`  
**When** the developer runs `cd scripts && mypy --strict netcup_firewall.py`  
**Then** mypy reports zero errors  
**And** the generated client types are resolved without `Any` leakage into the CLI layer

---

### Phase 3a: Server Firewall Commands

#### Scenario 3a.1: Get current firewall state for a server interface

**Given** the operator is authenticated  
**And** server `cupix001` has interface with MAC `aa:bb:cc:dd:ee:ff`  
**And** the interface has firewall policies `[{"id": 42, "name": "lockdown"}, {"id": 99, "name": "ssh-temp-cupix001"}]`  
**When** they run `netcup-scp server firewall get --server cupix001 --mac aa:bb:cc:dd:ee:ff`  
**Then** the tool calls `GET /api/v1/servers/{serverId}/interfaces/aa:bb:cc:dd:ee:ff/firewall`  
**And** prints the firewall state as formatted JSON to stdout  
**And** exits with code `0`

#### Scenario 3a.2: Get firewall state in JSON output mode for scripting

**Given** the operator is authenticated  
**And** server `cupix001` has interface with MAC `aa:bb:cc:dd:ee:ff`  
**When** they run `netcup-scp server firewall get --server cupix001 --mac aa:bb:cc:dd:ee:ff --output json`  
**Then** the tool prints a single JSON object to stdout with `lowercase_underscore` keys  
**And** the object contains `user_policies`, `copied_policies`, `ingress_implicit_rule`, `egress_implicit_rule`, `consistent`, `active`  
**And** no log messages are emitted to stdout

#### Scenario 3a.3: Set firewall state by policy IDs

**Given** the operator is authenticated  
**And** user policies with IDs `42` and `99` exist in the SCP account  
**When** they run `netcup-scp server firewall set --server cupix001 --mac aa:bb:cc:dd:ee:ff --policy-ids 42,99 --yes`  
**Then** the tool calls `PUT /api/v1/servers/{serverId}/interfaces/aa:bb:cc:dd:ee:ff/firewall`  
**And** the request body is `{"userPolicies": [{"id": 42}, {"id": 99}], "copiedPolicies": []}`  
**And** on HTTP 200 the tool prints `Firewall updated for cupix001 interface aa:bb:cc:dd:ee:ff`  
**And** exits with code `0`

#### Scenario 3a.4: Set firewall prompts for confirmation without `--yes`

**Given** the operator is authenticated  
**When** they run `netcup-scp server firewall set --server cupix001 --mac aa:bb:cc:dd:ee:ff --policy-ids 42`  
**Then** the tool prints `About to overwrite firewall for cupix001 (aa:bb:cc:dd:ee:ff). Proceed? [y/N]`  
**And** waits for user input  
**And** if the user enters anything other than `y` or `Y`, prints `Aborted.` to stderr and exits with code `1`

#### Scenario 3a.5: Server not found returns a clear error

**Given** the operator is authenticated  
**When** they run `netcup-scp server firewall get --server nonexistent-host --mac aa:bb:cc:dd:ee:ff`  
**Then** the tool prints `Error: server 'nonexistent-host' not found` to stderr  
**And** exits with code `1`  
**And** does NOT print a raw Python traceback

---

### Phase 3b: User Firewall Policy Commands

#### Scenario 3b.1: List all user firewall policies

**Given** the operator is authenticated  
**And** the SCP account has user policies `[{"id": 42, "name": "lockdown"}, {"id": 99, "name": "ssh-temp-cupix001"}]`  
**When** they run `netcup-scp policy list`  
**Then** the tool calls `GET /api/v1/users/{userId}/firewall-policies`  
**And** prints a table with columns `ID`, `Name`, `Rules` to stdout  
**And** exits with code `0`

#### Scenario 3b.2: List policies in JSON output mode

**Given** the operator is authenticated  
**When** they run `netcup-scp policy list --output json`  
**Then** the tool prints a JSON array of policy objects to stdout  
**And** each object contains `id`, `name`, and `rules` keys  
**And** no log messages are emitted to stdout

#### Scenario 3b.3: Create a new named firewall policy from a JSON rules file

**Given** the operator is authenticated  
**And** a valid rules file `infra/firewall/cupix001-bootstrap.json` exists  
**When** they run `netcup-scp policy create --name cupix001-bootstrap --rules-file infra/firewall/cupix001-bootstrap.json`  
**Then** the tool calls `POST /api/v1/users/{userId}/firewall-policies` with the policy name and rules  
**And** on HTTP 201 prints `Created policy 'cupix001-bootstrap' with ID 123`  
**And** exits with code `0`

#### Scenario 3b.4: Create policy fails when name already exists

**Given** the operator is authenticated  
**And** a policy named `lockdown` already exists with ID `42`  
**When** they run `netcup-scp policy create --name lockdown --rules-file infra/firewall/lockdown.json`  
**Then** the tool prints `Error: policy named 'lockdown' already exists (ID 42)` to stderr  
**And** exits with code `1`  
**And** does NOT send a `POST` request

#### Scenario 3b.5: Update an existing policy's rules

**Given** the operator is authenticated  
**And** a policy named `cupix001-bootstrap` exists with ID `123`  
**And** a valid rules file `infra/firewall/cupix001-bootstrap.json` exists  
**When** they run `netcup-scp policy update --name cupix001-bootstrap --rules-file infra/firewall/cupix001-bootstrap.json --yes`  
**Then** the tool calls `PUT /api/v1/users/{userId}/firewall-policies/123` with the updated rules  
**And** on HTTP 200 prints `Updated policy 'cupix001-bootstrap' (ID 123)`  
**And** exits with code `0`

#### Scenario 3b.6: Delete a policy with confirmation

**Given** the operator is authenticated  
**And** a policy named `ssh-temp-cupix001` exists with ID `99`  
**When** they run `netcup-scp policy delete --name ssh-temp-cupix001`  
**Then** the tool prints `About to delete policy 'ssh-temp-cupix001' (ID 99). Proceed? [y/N]`  
**And** waits for user input  
**And** if the user enters `y`, calls `DELETE /api/v1/users/{userId}/firewall-policies/99`  
**And** on HTTP 204 prints `Deleted policy 'ssh-temp-cupix001' (ID 99)`  
**And** exits with code `0`

#### Scenario 3b.7: Delete with `--yes` skips confirmation prompt

**Given** the operator is authenticated  
**And** a policy named `ssh-temp-cupix001` exists with ID `99`  
**When** they run `netcup-scp policy delete --name ssh-temp-cupix001 --yes`  
**Then** the tool calls `DELETE /api/v1/users/{userId}/firewall-policies/99` without prompting  
**And** exits with code `0`

#### Scenario 3b.8: Delete policy that does not exist

**Given** the operator is authenticated  
**When** they run `netcup-scp policy delete --name nonexistent-policy --yes`  
**Then** the tool prints `Error: policy named 'nonexistent-policy' not found` to stderr  
**And** exits with code `1`  
**And** does NOT send a `DELETE` request

#### Scenario 3b.9: Rules file fails JSON schema validation

**Given** the operator is authenticated  
**And** a malformed rules file `infra/firewall/bad.json` exists with an invalid `action` value  
**When** they run `netcup-scp policy create --name bad-policy --rules-file infra/firewall/bad.json`  
**Then** the tool validates the rules file against the `FirewallPolicy` schema before sending any HTTP request  
**And** prints a validation error identifying the invalid field to stderr  
**And** exits with code `2`

---

## Technical Details

**DEV Notes:**

- Phase 1 adds a new `openapi` subcommand group to [`scripts/netcup_firewall.py`](scripts/netcup_firewall.py); no generated code yet
- Phase 2 tooling: evaluate [`openapi-python-client`](https://github.com/openapi-generators/openapi-python-client) or `datamodel-code-generator` for the generation step; user will provide the downloaded spec file — generation is a one-time developer action, not a runtime CLI command
- Generated client output target: `scripts/scp_client/` (added to devShell `PYTHONPATH`)
- Phase 3a `server firewall get/set` replaces the inline HTTP calls in `set_firewall()` (line ~450) with the generated client methods
- Phase 3b `policy` commands are new functionality; the `userId` is resolved at runtime from `GET /api/v1/userinfo` (already used in `ScpAuth.get_user_info()`)
- All commands must respect `--output {text,json}` and `--verbose` / `--quiet` flags (see `PY-CLI-001`)
- Destructive commands (`set`, `delete`, `update`) must have `--yes` flag checked in handler body (not just declared in argparse) — see rule PY-CLI-001
- All HTTP calls: `timeout=(10, 30)`, retry on 5xx with `backoff_factor=1`, max 3 retries, no retry on 4xx

**QA Notes:**

- All unit tests mock HTTP via `responses` or `unittest.mock.patch`; no real SCP API calls in tests
- Test data: use realistic API response shapes from the OpenAPI spec (matching `ServerFirewall`, `FirewallPolicy` schemas)
- Phase 3b policy CRUD tests must cover: list empty, list non-empty, create success, create duplicate-name error, update success, update not-found error, delete with confirmation, delete with `--yes`, delete not-found error
- Regression: all 130+ existing tests in [`scripts/tests/test_netcup_firewall.py`](scripts/tests/test_netcup_firewall.py) must continue to pass after each phase
- Quality gates per phase: `mypy --strict`, `ruff check`, `ruff format --check` must all pass

---

## Open Points

| Question | Answer/Decision | Responsible |
|----------|-----------------|-------------|
| Which OpenAPI client generator to use (`openapi-python-client` vs `datamodel-code-generator`)? | To be decided in Phase 2 kickoff | Dan |
| Should the generated client be committed to git or regenerated from spec on each `nix build`? | Commit generated code (simpler devShell, avoids network dependency in Nix build) | Dan |
| What is the stable `userId` resolution path — from `userinfo` endpoint or from stored credentials? | Resolve from `GET /api/v1/userinfo` at runtime using existing `ScpAuth.get_user_info()` | Dan |
| Should deprecated commands (`backup`, `restore`, `lockdown`, `ssh-open`, `ssh-close`) be removed in this story or a follow-up? | Out of scope for this story; deprecate with warning in a follow-up | Dan |
| Does the SCP `DELETE /firewall-policies/{id}` endpoint return 204 or 200? | To be verified against downloaded OpenAPI spec in Phase 1 | Dan |
