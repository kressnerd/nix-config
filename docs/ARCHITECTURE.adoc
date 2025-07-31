= Nix Configuration Architecture
:toc: left
:toclevels: 3
:sectnums:
:icons: font

This document provides a unified overview of the structure, modularity, and layering of the Nix configuration repository. It consolidates the architectural insights previously found in FLAKE.adoc, MODULES.adoc, and HOSTS.adoc.

== Overview

The repository is organized for modularity, maintainability, and scalability. It uses a layered approach:

* **Flake-based entry point** for reproducible builds and input management
* **System-level configuration** with nix-darwin and Homebrew
* **User-level configuration** with Home Manager and feature modules
* **Secrets management** with SOPS and age

== Flake Structure

The `flake.nix` file defines all external dependencies (inputs), overlays, and outputs. It composes system and user configurations, passing special arguments for advanced composition.

== System and Host Layer

Each host has a dedicated directory under `hosts/`, containing system-level configuration (`default.nix`) and secrets. System configuration manages:

* Platform and state version
* User account setup for Home Manager
* Declarative Homebrew integration
* Minimal system-wide packages
* Activation scripts for runtime checks

== User and Feature Layer

User configuration is modular and lives under `home/dan/`. It imports:

* Global settings (`global/default.nix`)
* Feature modules (`features/cli/`, `features/macos/`, `features/productivity/`)
* Host-specific overrides

Feature modules encapsulate CLI tools, macOS settings, productivity apps, and more. Each module is self-contained and composable.

== Modularity and Extensibility

* Features are added by creating new modules and importing them in the user config.
* Secrets are defined globally and referenced where needed.
* The architecture supports incremental adoption and cross-platform expansion.

== Architectural Patterns

* **Layered composition**: System → User → Features
* **Declarative management**: All configuration is code, not imperative commands
* **Separation of concerns**: System, user, and secrets are managed independently
* **Extensible modules**: New features can be added without disrupting existing configs

== Adding or Modifying Hosts

To add a new host:
. Create a new directory under `hosts/`
. Add system configuration and secrets
. Create a user configuration in `home/dan/`
. Register the host in `flake.nix`

== Future Evolution

The structure is designed for:
* Multi-host and cross-platform support
* Custom overlays and package extensions
* CI/CD and automated validation
* Infrastructure as Code integration

For detailed examples and up-to-date module patterns, see the codebase and feature modules.