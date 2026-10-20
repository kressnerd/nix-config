@givn.delta @security-key-enrollment-and-authorization

Feature: Enrolling and authorizing security keys for the personal identity

  The personal identity is represented by a daily security key, a backup security key, and the retained file-backed identity. Each token-held credential is non-resident: the handle file stays on the device, and the remote must authorize the public identity.

  @givn.added @wip @host:thiniel
  Scenario: The device declares support for both security keys and the fallback
    Given thiniel is declared with the personal identity and two security keys
    When the host configuration is evaluated
    Then the host declares access to the daily and backup security keys
    And the identity declaration names the daily credential, the backup credential and the file-backed fallback
    And the daily credential is preferred
    And no resident credential is required

  @givn.added @wip @e2e @check:integration-security-key-authentication
  Scenario: A recognized security key is not authorized until its public identity is granted
    Given a security key has been enrolled for the personal identity
    And its public identity is not authorized at a remote
    When the device attempts a connection to that remote
    Then the remote does not accept the connection
    And the device reports that the public identity is not authorized

  @givn.added @wip @check:security-key-fleet-authorizations
  Scenario: Every declared host authorizes the personal token public identities
    Given the daily and backup token public identities are declared for the personal identity
    When every declared host that accepts the user's SSH key is evaluated
    Then each such host authorizes both public identities
    And no work identity is replaced

  @givn.added @wip @check:unit-security-key-identity
  Scenario: The identity declaration records both token credentials and the fallback order
    Given the personal identity is declared with a daily and a backup security key
    When the identity declaration is rendered
    Then it names both public identities
    And it names the file-backed fallback
    And the daily token is preferred

  @givn.added @wip @e2e @check:integration-security-key-authentication
  Scenario: The daily key authenticates at the designated test remote after enrollment and authorization
    Given the daily security key is enrolled with a non-resident handle
    And its public identity is authorized at the designated test remote
    When the owner opens a connection with the daily key and touches it
    Then the remote accepts the connection
    And the key offers no recoverable resident credential
