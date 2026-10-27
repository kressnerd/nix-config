@givn.delta @rust-build-toolchain
Feature: Rust build toolchain on the personal laptop

  @givn.modified @e2e @check:integration-rust-toolchain
  Scenario: A booted device builds and runs a Rust project
    Given a device that declares the Rust build toolchain
    When  the device boots and a new Rust project is built
    Then  the build produces a program that runs and prints its greeting
    And   the device runs the project's Clippy lint without errors
    And   the device formats the project's sources without changes
    And   the formatter and lint driver are the compiler's own components

  @givn.added @e2e @check:integration-rust-toolchain
  Scenario: A booted device measures coverage of a Rust project
    Given a device that declares the Rust build toolchain
    When  the device boots and builds a Rust project with coverage instrumentation
    Then  the device merges the profile with the coverage tools of the declared toolchain
    And   the report counts lines that the project's test exercised
