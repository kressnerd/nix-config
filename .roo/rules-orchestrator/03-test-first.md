# MANDATORY RULE: Test-First Delegation Sequence

## Rule ID: ORCH-TEST-001

**Priority**: MANDATORY  
**Applies to**: All Orchestrator delegations involving configuration changes

## Core Rule

The Orchestrator MUST delegate the Red (failing test) and Green (passing implementation) phases as **separate, sequential subtasks**. The test MUST demonstrably fail before the implementation subtask begins.

## Delegation Sequence

For every configuration change, the Orchestrator follows this sequence, with **one minimal change per Red-Green pair**:

| Step | Mode | Action | Verification |
|------|------|--------|-------------|
| 1 | `architect` | Plan change + identify required test type | Test type determined |
| 2 | `code` | **Red**: Write failing test (assertion, unit, or integration) | Test EXISTS |
| 3 | `code` | **Verify Red**: Run test, confirm it FAILS | FAIL confirmed |
| 4 | `code` | **Green**: Implement the configuration change | Change applied |
| 5 | `code` | **Verify Green**: Run test, confirm it PASSES | PASS confirmed |
| 6 | `code` | **Refactor** (optional): Restructure while tests pass | All tests PASS |
| 7 | `code` | **Pre-deploy gate**: `nix flake check` must pass | PASS confirmed |
| 8 | `code` | **Deploy** (if applicable): `nixos-rebuild switch` | Applied |

## Test Type Selection

The Orchestrator MUST select the appropriate test type based on the change:

| Change Type | Test Type | File Location | Verify Command |
|-------------|-----------|---------------|----------------|
| Helper function / pure Nix logic | `lib.debug.runTests` | `tests/unit/<name>-test.nix` | `nix flake check` |
| Module option constraint | NixOS `assertions` | `tests/assertions/<name>-invariants.nix` | `nix flake check --no-build` |
| Service behavior / firewall / networking | `testers.runNixOSTest` | `tests/integration/<name>-test.nix` | `nix build .#checks.<system>.<name>` |
| Post-deployment state | `pytest-testinfra` | `tests/deploy/test_<host>.py` | `pytest --hosts=ssh://...` |
| Python script logic | `pytest` | `scripts/tests/test_<tool>.py` | `cd scripts && python3 -m pytest tests/ -v` |

## Atomic Step Size

Each Red-Green pair delegated by the Orchestrator MUST cover exactly **one minimal change**. The Orchestrator breaks features into the smallest testable increments.

### Decomposition Rule

When delegating a feature that requires multiple configuration changes:

1. **Decompose** the feature into individual testable steps
2. **Delegate** one Red-Green cycle per step
3. **Verify** each cycle passes before starting the next
4. **Refactor** only after multiple Green cycles accumulate

### Example: "Enable SSH with hardened config"

Do NOT delegate as one task. Decompose into:

```
Subtask 1 (Red):   Write test: SSH service must be active
Subtask 2 (Green): Enable services.openssh.enable = true → test passes
Subtask 3 (Red):   Write test: root login must be disabled
Subtask 4 (Green): Set PermitRootLogin = "no" → test passes
Subtask 5 (Red):   Write test: password auth must be disabled
Subtask 6 (Green): Set PasswordAuthentication = false → test passes
Subtask 7:         Refactor if needed → all tests still pass
```

### Prohibited Delegation Patterns

- ❌ `"Write all SSH tests and implement SSH config"` (too large)
- ❌ `"Add 5 assertions for the new service"` (batch test creation)
- ✅ `"Write one assertion: SSH root login must be disabled"` (atomic)
- ✅ `"Implement: set PermitRootLogin = no to pass the assertion"` (atomic)

## Batching Similar Features

The default is **one change per Red-Green pair**. The Orchestrator MAY batch multiple features into a single subtask when ALL conditions hold:

- All features follow an **identical pattern** (same option path, same test structure)
- No feature has a unique failure mode (homogeneous pass/fail)
- The batch constitutes a **single logical change** (e.g., "add 3 messaging apps with persistence")
- The batch remains **small** (≤ 5 items); larger groups must be split

### Prohibited Batching

- Features with different configuration structures or option paths
- Features that could fail independently
- Mixed change types (e.g., package addition + service enable + firewall rule)

## Subtask Message Templates

### Red Phase (Write Failing Test)

```
TASK: Write failing test for [feature/change]
LOCATION: tests/<type>/<name>-test.nix
SPEC: [What the test should verify — expected behavior that does NOT yet exist]
VERIFY: [Command that must FAIL] → confirm FAIL
CONTEXT:
- Test type: [unit | assertion | integration | deploy]
- This test must FAIL because [reason — the feature is not yet implemented]
- Follow pattern from tests/<type>/<existing-example>.nix
```

### Green Phase (Implement Change)

```
TASK: Implement [feature/change] to make test pass
LOCATION: [path/to/config.nix]
SPEC: [What to implement]
VERIFY: [Same command from Red phase] → confirm PASS
CONTEXT:
- The failing test is at tests/<type>/<name>-test.nix
- After implementation, run: [verification command]
- All existing tests must continue to pass
```

## Prohibitions

The Orchestrator MUST NOT:

- Delegate test + implementation in the same subtask
- Skip the Red phase verification (test must demonstrably fail)
- Proceed to Green without confirmed Red
- Deploy without passing `nix flake check`

## Exceptions

Test delegation is NOT required for changes listed in TEST-FIRST-001 exceptions:
- Documentation-only changes (`.md` files)
- `nix flake update`
- SOPS secret value changes
- Formatting-only changes

## Enforcement

- Subtask result from Red phase MUST contain `FAIL confirmed` or equivalent
- Subtask result from Green phase MUST contain `PASS confirmed` or equivalent
- Any Green subtask delegated without a preceding Red subtask = rule violation
