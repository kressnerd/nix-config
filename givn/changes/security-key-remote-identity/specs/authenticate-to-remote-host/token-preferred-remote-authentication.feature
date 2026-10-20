@givn.delta @token-preferred-remote-authentication

Feature: Token-preferred remote authentication

  Normal connections use the token. The retained file-backed identity is available only through the named fallback. The device never substitutes one credential for another silently.

  @givn.added @wip @host:thiniel
  Scenario: Normal connections use the daily token and not the file-backed identity
    Given thiniel declares the daily security key as the personal identity
    And the file-backed identity is declared only for the named fallback
    When the host configuration is evaluated
    Then the default private-repository connection uses the daily token credential
    And the default connection does not offer the file-backed identity
    And the named fallback selects the file-backed identity

  @givn.added @wip @check:unit-security-key-identity
  Scenario: The daily token is selected when it is available
    Given the daily token credential is available
    And the file-backed identity is available
    When a normal connection selects a credential
    Then the daily token credential is selected
    And the file-backed identity is not selected silently

  @givn.added @wip @check:unit-security-key-identity
  Scenario: An absent daily token uses the backup token
    Given the daily token credential is unavailable
    And the backup token credential is available
    When a normal connection selects a credential
    Then the backup token credential is selected
    And the file-backed identity is not selected automatically

  @givn.added @wip @check:unit-security-key-identity
  Scenario: Both tokens unavailable require the named fallback
    Given both token credentials are unavailable
    When a normal connection is attempted
    Then no credential is selected automatically
    And the named fallback is required to use the file-backed identity

  @givn.added @wip @e2e @check:integration-security-key-authentication
  Scenario: A token connection succeeds only with a touch
    Given the daily security key is present and its handle file is readable
    When the owner opens a connection and touches the key
    Then the remote accepts the connection

  @givn.added @wip @e2e @check:integration-security-key-authentication
  Scenario: A token connection without a touch is rejected
    Given the daily security key is present and its handle file is readable
    When the owner opens a connection and does not touch the key
    Then the remote does not accept the connection

  @givn.added @wip @e2e @check:integration-security-key-authentication
  Scenario: A token without its handle file does not authenticate
    Given the daily security key is present on a host without its handle file
    When the owner attempts a connection
    Then the remote does not accept the connection
    And the device does not silently substitute the file-backed identity

  @givn.added @wip @check:unit-security-key-identity
  Scenario: A rejected daily credential may use the backup token
    Given the daily public identity is rejected at the remote
    And the backup token credential is available
    When a normal connection selects a credential
    Then the backup token credential is offered
    And the file-backed identity is not selected automatically

  @givn.added @wip @e2e @check:integration-security-key-authentication
  Scenario: A rejected daily credential is not retried with the file-backed identity
    Given the remote has revoked the daily public identity
    When the owner attempts a connection with the daily key
    Then the remote rejects the connection
    And the device does not silently use the file-backed identity
