@givn.delta @current-agent-tooling

Feature: Current coding agent on a personal device

  A device carries the owner's everyday coding agent at or above the accepted
  version floor and with the repository's guardrails, so a reproduced working
  environment is not a device whose agent has fallen days behind its source,
  and the same agent refuses the same decryption work on every device that
  carries it.

  @givn.added @host:thiniel
  Scenario: The personal laptop carries a current, guarded coding agent
    Given the personal laptop thiniel carries the owner's coding agent
    When the device configuration is applied
    Then the coding agent is Oh My Pi (omp)
    And the agent's version is at least 18.10
    And the device declares the secret-access guard for installation in the agent's user directory

  @givn.added @host:J6G6Y9JK7L
  Scenario: The work MacBook carries the personal laptop's current, guarded coding agent
    Given the work MacBook carries the owner's coding agent
    When the device configuration is applied
    Then the coding agent is Oh My Pi (omp)
    And the agent's version is at least 18.10
    And the agent declares the same two shared model servers as the personal laptop: documentation lookup and web search
    And the device declares the secret-access guard for installation in the agent's user directory

  @givn.added @wip @check:unit-agent-secret-guard
  Scenario: A decryption attempt is refused on a device that carries the guard
    Given a device carries the owner's coding agent and its secret-access guard
    When a session submits a decryption command, or reads or searches the runtime secret directory, the age key file, or the sops-nix system directory
    Then the guard refuses the call and reports the repository's policy reason

  @givn.added @wip @check:unit-agent-secret-guard
  Scenario: Ordinary repository work passes the guard
    Given a device carries the owner's coding agent and its secret-access guard
    When a session submits an ordinary repository read or an ordinary command
    Then the guard does not refuse the call

  @givn.added @wip @e2e @check:integration-agent-tooling
  Scenario: A booted device starts its coding agent
    Given a device that carries the owner's coding agent and none of its servers' key material
    When the device boots and its configuration is applied
    Then the coding agent starts and reports a version of at least 18.10
    And the secret-access guard is present as a regular file in the agent's user directory
