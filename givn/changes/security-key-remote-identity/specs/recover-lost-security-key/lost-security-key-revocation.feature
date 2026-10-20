@givn.delta @lost-security-key-revocation

Feature: Revoking a lost security key's public identity

  A lost key's public identity is revoked at every remote that authorized it. A failed, unreachable, or unverified revocation is not success. The remaining credential and the file-backed identity remain available.

  @givn.added @wip @host:thiniel
  Scenario: The identity declaration names the public identities and the remotes that authorize them
    Given the personal identity is declared with a daily and a backup security key
    When the host configuration is evaluated
    Then the identity declaration names both public identities
    And it names every declared remote that authorizes them

  @givn.added @wip @check:unit-security-key-identity
  Scenario: A lost daily key is revoked at every remote while the backup is retained
    Given the daily security key is lost and the backup key is available
    When the revocation plan is computed
    Then the daily public identity is revoked at every declared remote
    And the backup public identity is not revoked
    And the file-backed identity remains available

  @givn.added @wip @check:unit-security-key-identity
  Scenario: Both lost keys are revoked and the file-backed identity remains
    Given both security keys are lost and the file-backed identity is available
    When the revocation plan is computed
    Then both public identities are revoked at every declared remote
    And the file-backed identity remains available

  @givn.added @wip @check:unit-security-key-identity
  Scenario: A failed revocation is not reported as removed
    Given a remote cannot confirm the revocation of a lost public identity
    When the owner checks the revocation result
    Then that remote is reported as not revoked
    And the completed remotes are reported separately

  @givn.added @wip @host:thiniel
  Scenario: A lost public identity is removed from the declaration and the remaining identity stays authorized
    Given the lost public identity has been removed from the active identities
    When the host configuration is evaluated
    Then the declaration names the remaining public identity
    And the lost public identity is not authorized

  @givn.added @wip @e2e @check:integration-security-key-revocation
  Scenario: A lost public identity is revoked at the designated test remote and no longer authenticates
    Given a lost public identity is authorized at the designated test remote
    And the remaining credential can authenticate there
    When the owner revokes the lost public identity
    Then the test remote confirms it is no longer authorized
    And the remaining credential still authenticates
