# MANDATORY RULE: Test Writing and Validation

## Rule ID: CODE-TEST-001

**Priority**: MANDATORY  
**Applies to**: All Code Mode tasks involving test creation or test verification

## Core Rule

When delegated a test-writing task (Red phase) or test-verification task, Code Mode MUST follow the patterns below and report test results explicitly.

## Test Writing Patterns

### Unit Test (`lib.debug.runTests`)

```nix
# tests/unit/<name>-test.nix
{ lib }:
lib.debug.runTests {
  test<Name> = {
    expr = <expression>;
    expected = <expected-value>;
  };
}
```

Aggregator wrapper:
```nix
# tests/unit/default.nix (add new test to existing aggregator)
pkgs.runCommand "unit-<name>" { } ''
  ${if tests == [ ] then "echo 'PASS'; touch $out"
    else "echo 'FAIL: ${builtins.toJSON tests}'; exit 1"}
''
```

### Module Assertion

```nix
# tests/assertions/<scope>-invariants.nix
{ config, lib, ... }:
{
  config.assertions = [
    {
      assertion = <condition>;
      message = "<scope> invariant violated: <description>";
    }
  ];
}
```

### Integration Test (`testers.runNixOSTest`)

```nix
# tests/integration/<name>-test.nix
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "<test-name>";
  nodes.machine = { ... }: {
    # minimal config for the feature under test
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("<service>.service")
    machine.succeed("<verification-command>")
  '';
}
```

## Red Phase Obligations

When writing a **failing test** (Red phase):

1. Write the test file at the correct location under `tests/`
2. Wire the test into the appropriate aggregator (`tests/<type>/default.nix`)
3. If new, add the check attribute to `flake.nix` `checks` output
4. Run the verification command and **confirm it FAILS**
5. Report: `RED CONFIRMED: <test-name> fails as expected`

## Green Phase Obligations

When verifying a test **passes** (Green phase):

1. Run the same verification command used in Red phase
2. Confirm it **PASSES**
3. Run `nix flake check` to ensure no regressions
4. Report: `GREEN CONFIRMED: <test-name> passes`

## Return Format Extension

Test-related tasks MUST include a `TESTS:` block in the DONE response:

```
STATUS: DONE
RESULT: [description]
FILES: [list]
VALIDATION:
- flake check: PASS/FAIL
- build: PASS/FAIL/SKIPPED
TESTS:
- <test-name>: RED CONFIRMED / GREEN CONFIRMED / PASS / FAIL
- regression: PASS (N existing tests unaffected)
QUALITY:
- deadnix: PASS/FAIL
- statix: PASS/FAIL
- format: PASS/FAIL
```

## Test Naming Conventions

| Test Type | Check Attribute Name | File Name |
|-----------|---------------------|-----------|
| Unit | `unit-<module>` | `tests/unit/<module>-test.nix` |
| Assertion | (fires via host eval) | `tests/assertions/<scope>-invariants.nix` |
| Integration | `integration-<feature>` | `tests/integration/<feature>-test.nix` |

## Prohibitions

Code Mode MUST NOT:

- Write tests and implementation in the same subtask (unless explicitly instructed)
- Skip running the verification command
- Report DONE without the `TESTS:` block when working on test-related tasks
- Modify existing tests to weaken assertions

## Step Size

Each test-writing subtask targets exactly **one behavior**. Code Mode MUST:

- Write **one test case** (or one assertion) per Red subtask
- Implement **one configuration change** per Green subtask
- Report exactly what was tested and what was changed

If the delegated task specifies multiple tests or changes, Code Mode MUST:
1. Implement only the first one
2. Return PARTIAL with the remaining items listed
3. Wait for the Orchestrator to delegate the next step

## Verification Commands Quick Reference

| Test Type | Verify Command |
|-----------|---------------|
| Unit | `nix flake check` or `nix build .#checks.<system>.unit-<name>` |
| Assertion | `nix flake check --no-build` |
| Integration | `nix build .#checks.<system>.integration-<name>` |
| All | `nix flake check` |

## Python Tests (pytest)

For Python code in `scripts/`, use `pytest` instead of Nix test tools. See PY-TDD-001 in [`.roo/rules/14-python-tdd.md`](../rules/14-python-tdd.md).

- Test location: `scripts/tests/test_<tool>.py`
- Framework: `pytest`
- Verification: `cd scripts && python3 -m pytest tests/ -v`
- Minimum coverage per CLI tool: unit tests (mocked APIs), exit code test, `--help` test
- Template and scaffold: see [`create-python-cli-tool`](../skills/create-python-cli-tool/SKILL.md) skill
