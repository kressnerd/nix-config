@givn.delta @rust-build-toolchain
Feature: Rust build toolchain on the personal laptop

  @givn.added @host:thiniel
  Scenario: The personal laptop provides the Rust compiler and Cargo
    Given the personal laptop thiniel is the selected device
    When  the device configuration is applied
    Then  the device provides the Rust compiler and Cargo
    And   the device provides a C linker and pkg-config that a Rust build needs

  @givn.added @host:thiniel
  Scenario: The personal laptop keeps the Cargo home across boots
    Given the personal laptop thiniel is the selected device
    When  the device configuration is applied
    Then  the device declares the Cargo home as persistent

  @givn.added @wip @e2e @check:integration-rust-toolchain
  Scenario: A booted device builds and runs a Rust project
    Given a device that declares the Rust build toolchain
    When  the device boots and a new Rust project is built
    Then  the build produces a program that runs and prints its greeting
    And   the device runs the project's Clippy lint without errors
