@givn.delta @operational-data-separation

Feature: Operational data separation

  The published configuration records no operational value, and every host still
  builds and deploys from the values held outside the repository. A host whose
  values are not supplied by a private source declares a non-operational
  placeholder instead (a documentation-range address or an empty value), and a
  revision that would record an operational value, a per-host private-value
  file, or an unencrypted secret is refused.

  @givn.added @check:private-data-defaults
  Scenario: A host declares placeholders when no private source supplies its values
    Given the home server's values are not supplied from outside the repository
    When the home server's configuration is evaluated
    Then its declared LAN address and gateway are documentation-range addresses
    And its declared WireGuard subnet and server address are generic private-range placeholders

  @givn.added @check:private-data-hygiene
  Scenario: The repository records no operational value
    Given the repository's recorded content
    When the hygiene check runs over it
    Then no operational address, gateway, hardware address, provider resolver or non-standard port appears
    And no per-host private-value file is recorded
    And no unencrypted secret file is recorded

  @givn.added @check:private-data-hygiene
  Scenario: The hygiene rule rejects recorded content that contains an operational value
    Given recorded content that contains an operational network value
    When the hygiene rule is applied to it
    Then the rule reports the offending location and rejects the content

  @givn.added @check:private-data-hygiene
  Scenario: The hygiene rule rejects a recorded per-host private-value file or unencrypted secret
    Given recorded content that contains a per-host private-value file and an unencrypted secret file
    When the hygiene rule is applied to it
    Then the rule rejects the content and names both offending paths

  @givn.added @e2e @check:integration-private-data-separation
  Scenario: A host booted with values supplied from outside the repository uses those values
    Given a host whose network values are supplied from a source outside the repository
    When the host boots with that source
    Then its network interface carries the supplied address and gateway
