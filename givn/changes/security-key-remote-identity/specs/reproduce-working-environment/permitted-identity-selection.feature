@givn.delta @permitted-identity-selection

Feature: Permitted identity selection on a personal device (security-key delta)

  The personal laptop now holds a daily token handle plus the file-backed fallback.
  The work MacBook keeps its file-based identity selection.

  @givn.modified @wip @host:thiniel
  Scenario: The personal device reaches private repositories with the identity it holds
    Given the personal laptop thiniel holds the daily token handle and the file-backed fallback
    When the device configuration is applied
    Then the private-repository connection resolves to the daily token handle
    And the named fallback selects the file-backed identity
    And the identity configuration used inside the private workspace names the daily token handle

