@givn.delta @quiet-configuration-evaluation

Feature: Quiet configuration evaluation

  @givn.added @wip @host:thiniel
  Scenario: The personal laptop states its compositor configuration format
    Given the personal laptop's compositor configuration format was changed by a newer release
    And   its home profile was created before that change
    When  the personal laptop's configuration is evaluated
    Then  the device states the compositor configuration format itself, so no superseded-default diagnostic is reported
    And   the rendered compositor configuration is the conf-format file in use today
    And   no Lua-format compositor configuration is rendered

  @givn.added @wip @host:thiniel
  Scenario: The personal laptop's browser profile lives under its XDG config directory and survives a root reset
    Given the personal laptop's browser profile location was changed by a newer release
    And   its home profile was created before that change
    When  the personal laptop's configuration is evaluated
    Then  the browser profile is rendered under `~/.config/mozilla/firefox` and none is rendered under `~/.mozilla/firefox`
    And   no superseded-default diagnostic is reported for the profile
    And   the device's persistent set covers the profile directory, so the browsing state survives the root-filesystem reset

  @givn.added @wip @e2e @check:integration-ssh-identity-selection
  Scenario: A booted device reproduces its identity surface from a single release
    Given a device whose home profile is built from the Home Manager release its package set comes from
    When  the device boots and its configuration is applied
    Then  it applies the profile without reporting a release-mismatch diagnostic
    And   the declared identity surface is rendered on the device

  @givn.added @wip @e2e @check:integration-agent-tooling
  Scenario: A booted device starts its coding agents from a single release
    Given a device whose home profile is built from the Home Manager release its package set comes from
    When  the device boots and its configuration is applied
    Then  it applies the profile without reporting a release-mismatch diagnostic
    And   both coding agents start

  @givn.added @wip @check:flake-output-contract
  Scenario: The flake exposes only outputs the checker interprets
    Given the repository's flake
    When  its declared outputs are inspected
    Then  every declared output is one the checker interprets
