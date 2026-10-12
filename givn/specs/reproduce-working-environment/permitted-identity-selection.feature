Feature: Permitted identity selection on a personal device

  @host:thiniel
  Scenario: The personal device reaches private repositories with the identity it holds
    Given  the personal laptop thiniel holds the private key ~/.ssh/id_ed25519 as its only personal identity
    When  the device configuration is applied
    Then  the private-repository connection resolves to the identity file ~/.ssh/id_ed25519
    And  the identity configuration used inside the private workspace names the same identity file

  @host:thiniel
  Scenario: A device declares no connection for an identity whose material it does not hold
    Given  the personal laptop thiniel holds no secret material for the company, client001 and client002 identities
    When  the device configuration is applied
    Then  the device declares no connection entry for the company, client001 and client002 identities
    And  the device includes no manually maintained work-laptop SSH configuration file

  @host:J6G6Y9JK7L
  Scenario: The work laptop keeps its per-purpose identity selection
    Given  the work MacBook holds the personal, company, client001 and client002 identity material
    When  the device configuration is applied
    Then  the private-repository connection resolves to the identity file ~/.ssh/id_ed25519_personal_2026-10-04
    And  the identity configuration used inside the private workspace names the same identity file
    And  the company, client001 and client002 connection entries remain declared
    And  the three manually maintained work-laptop SSH configuration files remain included

  @e2e @check:integration-ssh-identity-selection
  Scenario: A booted device reaches private repositories with the identity it declares
    Given  a device declares ~/.ssh/id_ed25519 as its personal identity and holds no work identity material
    When  the device boots and its configuration is applied
    Then  the private-repository connection resolves to the identity file ~/.ssh/id_ed25519
    And  the device declares no work identity connection entry
