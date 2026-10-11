# Binding tags — canonical model in docs/GIVN-VERIFICATION.md:
#   @check:<name>   a flake check:     nix build .#checks.<system>.<name>
#   @host:<name>    a host evaluation: fires tests/assertions invariants
#   @deploy:<name>  a live-host test:  pytest tests/deploy/test_<name>.py
# Every scenario carries exactly ONE binding tag, on the line before
# `Scenario:`. @e2e scenarios MUST bind to @check:integration-<name>,
# @host:<name>, or @deploy:<name> — a real boot or live host, never an
# evaluation-only unit/lint check.

@givn.delta @{{CAPABILITY}}
Feature: {{FEATURE_TITLE}}

  # Scenarios assert observable host/system state: a service active and
  # listening, a firewall accepts or drops, a file/user/group/systemd unit
  # present, a secret materialised at a path with owner/mode, the system
  # evaluates and every assertion holds, or state after a boot.
  # Do NOT mention module paths, option names, helper functions, or
  # derivation internals.
  # Tag new scenarios @givn.added, changed ones @givn.modified, deleted ones
  # @givn.removed. Tag @wip while the bound target is not yet implemented —
  # the reference scenarios below omit @wip because they are not live deltas.

  @givn.added @host:thiniel
  Scenario: {{SCENARIO_TITLE}}
    Given the thiniel host configuration
    When the host configuration is evaluated
    Then every declared assertion holds and the system evaluates

  # @e2e smoke test: proves a real boot or a live host, run by verify.e2e_command.

  @givn.added @e2e @check:integration-vm-minimal-ssh
  Scenario: A booted system accepts an SSH connection
    Given a booted VM
    When an SSH connection is opened to the guest
    Then the connection is accepted
