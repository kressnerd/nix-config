@givn.delta @current-agent-tooling

Feature: Current coding agent on a personal device

  Extends the capability with the second coding agent the devices carry: both
  devices carry OpenCode at or above the accepted version floor, so a
  reproduced working environment is not a device whose OpenCode has fallen days
  behind its source.

  @givn.added @host:thiniel
  Scenario: The personal laptop carries a current OpenCode
    Given the personal laptop thiniel carries the OpenCode coding agent
    When the device configuration is applied
    Then the OpenCode version is at least 2.0.28

  @givn.added @host:J6G6Y9JK7L
  Scenario: The work MacBook carries the personal laptop's current OpenCode
    Given the work MacBook carries the OpenCode coding agent
    When the device configuration is applied
    Then the OpenCode version is at least 2.0.28

  @givn.added @e2e @check:integration-agent-tooling
  Scenario: A booted device starts its OpenCode
    Given a device that carries the OpenCode coding agent
    When the device boots and its configuration is applied
    Then OpenCode starts and reports a version of at least 2.0.28
