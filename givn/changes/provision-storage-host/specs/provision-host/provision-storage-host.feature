@givn.delta @provision-storage-host

Feature: Accepting the storage host into the fleet

  `pronix` is accepted into the fleet only when its base system, storage layout,
  network attachment and declared storage roles are present. A host that boots
  without a declared pool, carries a conflicting address, or has a configured
  but non-answering storage role is reported as not accepted. `adlerkopf`
  remains in its separate `adlerhorst` LAN and is not changed.

  @givn.added @wip @host:pronix
  Scenario: The storage host evaluates with its declared pools, networks and roles
    Given pronix is declared as the storage and infrastructure host
    And its operational values are supplied from the approved private source
    When the host configuration is evaluated
    Then the configuration evaluates without diagnostics
    And the host declares its storage pools, LAN address, storage-network address and declared storage roles
    And no undeclared storage pool is declared

  @givn.added @wip @check:private-data-defaults
  Scenario: The storage host records no operational value in the public tree
    Given pronix's operational values are not supplied from outside the repository
    When the public configuration is evaluated
    Then its declared addresses are non-operational placeholders
    And no operational address, device identity or secret is recorded

  @givn.added @wip @check:unit-pronix-provisioning
  Scenario: A host with a missing declared storage pool is not accepted
    Given pronix is declared with a storage pool whose declared devices are absent from the storage layout
    When the host's acceptance is checked
    Then the host is reported as not accepted
    And the missing pool is named

  @givn.added @wip @check:unit-pronix-provisioning
  Scenario: A host with a conflicting address is not accepted
    Given pronix is declared with an address already used by another fleet host
    When the host's acceptance is checked
    Then the host is reported as not accepted
    And the conflicting address is named

  @givn.added @wip @check:unit-pronix-provisioning
  Scenario: A configured but non-answering storage role is not accepted
    Given pronix declares a storage role whose unit is configured but does not answer on its intended network
    When the host's acceptance is checked
    Then the host is reported as not accepted
    And the non-answering role is named

  @givn.added @wip @e2e @check:integration-pronix-storage
  Scenario: A booted storage host serves its declared exports and shares
    Given a pronix host booted with its declared storage layout, network values and storage roles
    When a client on the storage network mounts the declared media, photos, books, appdata and backup-staging exports
    And a declared family account authenticates to a declared share
    Then every declared export is readable
    And the declared share is accessible to the intended family account
    And the declared storage maintenance schedule is active
