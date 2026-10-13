@givn.delta @managed-file-displacement

Feature: A rewritten managed file is displaced, not fatal

  @givn.added @wip @e2e @check:integration-managed-file-displacement
  Scenario: A booted device activates although a program rewrote a managed file
    Given a device whose home profile manages a configuration file
    And   a program on that device rewrote that file after it was rendered
    When  the device boots and its configuration is applied
    Then  the activation completes
    And   the rendered file is in place
    And   what the program wrote is kept beside it under the displacement suffix

  @givn.added @host:thiniel
  Scenario: The personal laptop displaces a rewritten managed file
    Given the personal laptop's home profile manages configuration files
    When  the device's configuration is evaluated
    Then  the device is configured to move a rewritten managed file aside under the displacement suffix instead of aborting the activation

  @givn.added @host:J6G6Y9JK7L
  Scenario: The work MacBook displaces a rewritten managed file
    Given the work MacBook's home profile manages configuration files
    When  the device's configuration is evaluated
    Then  the device is configured to move a rewritten managed file aside under the displacement suffix instead of aborting the activation
