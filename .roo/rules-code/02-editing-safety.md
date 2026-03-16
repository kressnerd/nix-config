# Editing Rules & Safety — Nix Expert Mode

## Editing Principles

### Smallest Viable Change

- Produce the smallest diff that achieves the requested change
- Do not modify unrelated files or restructure without consent
- Ask before adding or updating flake inputs
- No approach conversions unless explicitly requested
- Deprecate gradually; avoid breaking changes
- Avoid verbose documentation; keep instructions concise and operational
- Preserve existing structure and style

### Factoring and Reuse

- Factor shared logic into modules (`modules/`) or helpers (`lib/`)
- No duplication across host configurations
- Feature modules in `home/dan/features/` must be self-contained
- Overlay composition via `overlays/default.nix` aggregator

### Import Wiring

- When creating new files, always wire imports in the consuming module
- New feature modules: add import in the appropriate `home/dan/<host>.nix`
- New host service files: add import in `hosts/<host>/default.nix`
- New overlays: add to `overlays/default.nix` aggregator

## Safety Rules (CRITICAL)

### State Version Protection

- **NEVER** change `system.stateVersion` or `home.stateVersion` unless the user is explicitly performing a major state upgrade
- These values are set at installation time and must not be modified during routine updates

### Hardware Configuration

- Treat `hardware-configuration.nix` / `hardware.nix` as **READ-ONLY**
- Only modify when explicitly changing kernel modules, filesystems, or hardware-specific settings
- Always note the change is to a hardware file

### Secrets

- **NEVER** commit plaintext secrets to the repository
- Use `sops-nix` with age encryption (`.sops.yaml` defines encryption rules)
- Secret files: `hosts/<host>/secrets.yaml`
- Key locations:
  - NixOS: `/var/lib/sops-nix/key.txt` or `/persist/var/lib/sops-nix/key.txt` (impermanence)
  - macOS: `~/Library/Application Support/sops/age/keys.txt`

### Dangerous Changes — Warn and Provide Rollback

For changes to these areas, **always warn** about potential impact and provide rollback instructions:

- **Bootloader** (`boot.loader.*`): Warn about reboot requirement; provide `sudo nixos-rebuild --rollback`
- **Networking** (`networking.*`, `systemd.network.*`): Warn about connectivity loss; test with `nixos-rebuild test` first
- **Filesystems** (`fileSystems.*`, `disko`): Warn about data loss risk; recommend backup
- **Impermanence** (`environment.persistence.*`): Warn about paths not persisting across reboot
- **Kernel** (`boot.kernelPackages`, `boot.kernelModules`): Warn about boot failure; provide generation switching

### Unfree Packages

- Check for `allowUnfree` predicate if adding proprietary packages (Discord, Chrome, Nvidia drivers)
- This repository sets `allowUnfree = true` in the flake overlay — verify it covers the target configuration

### Environment Safety

- No reliance on uninitialized environment; if shell setup is required, instruct to run in current active session
- Ephemeral `nix shell` for testing only; do not assume tools are globally available

### Dependency Updates

- Prefer `nix flake lock --update-input <name>` over global `nix flake update`
- Document which input was updated and why
- Test after update: `nix flake check` then `nixos-rebuild test`

## Output Format (MANDATORY)

Every change proposal MUST include:

1. **Rationale** — One sentence explaining why
2. **File list** — All paths being modified or created
3. **Unified diffs** — Per file, with enough context lines for uniqueness:
   ```
   --- a/path/to/file.nix
   +++ b/path/to/file.nix
   @@
   - old
   + new
   ```
4. **New file wiring** — Import statements to add (if creating new files)
5. **Validation checklist** — Relevant items only (see below)
6. **Apply commands** — Commands to test and apply the change

## Validation Checklist (pick relevant items)

- [ ] Syntax: `nix flake check`
- [ ] NixOS dry run: `sudo nixos-rebuild dry-activate --flake .#<hostname>`
- [ ] NixOS test (no boot switch): `sudo nixos-rebuild test --flake .#<hostname>`
- [ ] NixOS apply: `sudo nixos-rebuild switch --flake .#<hostname>`
- [ ] Home Manager: `home-manager switch --flake .#<user@host>`
- [ ] macOS: `darwin-rebuild switch --flake .#<host>`
- [ ] Options review: `nixos-option <option>`
- [ ] Service status: `systemctl status <unit>`
- [ ] Service logs: `journalctl -u <unit>`
- [ ] Rollback: `sudo nixos-rebuild --rollback` or generation switch

## Pre-Change Verification

Before making any change:

- [ ] Confirm target host/user and platform (NixOS vs macOS)
- [ ] Verify directory layout matches repository conventions
- [ ] Validate option paths via MCP or `nix repl`; avoid deprecated settings
- [ ] Use `nixos-rebuild test` before `switch` on servers

## Pre-Editing Clarification

Before making changes, confirm:

1. Target host/user and platform (NixOS, nix-darwin, or Home Manager standalone)
2. Exact desired change and constraints (offline, no rebuild now, specific host only)
3. Any additional context (new service, package addition, hardware change, boot adjustment)

Then propose changes using correct option paths:

- NixOS: `services.<name>`, `programs.<name>`, `networking.*`, `hardware.*`
- Home Manager: `home.packages`, `programs.<name>`, `services.<name>`, `xdg.*`
- Flake references: `nixpkgs#<package>`

## Success Criteria

Every completed change must satisfy:

- [ ] Clean diffs with minimal surface area
- [ ] Validation commands succeed (`nix flake check`, appropriate rebuild)
- [ ] No duplicated documentation; concise, clear instructions
- [ ] Commands only apply declared state; imperative actions are secondary
