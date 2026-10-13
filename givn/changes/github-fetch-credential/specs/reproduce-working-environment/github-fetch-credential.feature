@givn.delta @github-fetch-credential

Feature: GitHub fetch credential

  @givn.added @host:thiniel
  Scenario: The laptop declares the credential it presents to the GitHub host
    Given  the laptop thiniel develops and builds this configuration from its own checkout
    When   the device's configuration is evaluated
    Then   the device declares a GitHub fetch credential as secret material
    And    the declared credential file is readable by the device owner's account and by no other local account
    And    the device's nix configuration reads the credential from that file

  @givn.added @host:J6G6Y9JK7L
  Scenario: The work MacBook declares the credential it presents to the GitHub host
    Given  the work MacBook develops and builds this configuration from its own checkout
    When   the device's configuration is evaluated
    Then   the device declares a GitHub fetch credential as secret material
    And    the declared credential file is readable by the device owner's account and by no other local account
    And    the device's nix configuration reads the credential from that file

  @givn.added @host:adlerkopf
  Scenario: A host that does not build this configuration declares no credential
    Given  the home server adlerkopf is not a development or build machine
    When   the device's configuration is evaluated
    Then   the device declares no credential file
    And    the device's nix configuration carries no credential for the GitHub host

  @givn.added @wip @e2e @check:integration-github-fetch-credential
  Scenario: A booted device materialises the declared credential and presents it to the GitHub host
    Given  a device whose configuration declares a GitHub fetch credential and whose sessions carry nothing prepared
    When   the device boots
    Then   the credential file exists at the declared path, readable by the device owner's account and by no other local account
    And    nix reports for the GitHub host the credential the device declares, for the device owner's account
    And    nix reports for the GitHub host the credential the device declares, for root
