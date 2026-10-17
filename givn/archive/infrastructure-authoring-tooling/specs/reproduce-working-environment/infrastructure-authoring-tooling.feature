@givn.delta @infrastructure-authoring-tooling

Feature: Infrastructure authoring tooling on the personal laptop

  @givn.added @host:thiniel
  Scenario: The personal laptop provides an OpenTofu engine
    Given  the personal laptop thiniel is the selected device
    When  the device configuration is evaluated
    Then  the device provides an OpenTofu command-line engine

  @givn.added @host:thiniel
  Scenario: The personal laptop provides a GitHub command-line client
    Given  the personal laptop thiniel is the selected device
    When  the device configuration is evaluated
    Then  the device provides a GitHub command-line client
    And   the device registers no GitHub credential helper in its git configuration

  @givn.added @e2e @check:integration-infrastructure-tooling
  Scenario: A booted device runs its infrastructure and GitHub client tools
    Given  a device whose configuration provides OpenTofu and the GitHub command-line client
    When  the device boots and the owner invokes each tool
    Then  each tool reports its version
