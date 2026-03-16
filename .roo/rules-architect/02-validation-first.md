# Validation-First Planning

## Rule ID: ARCH-VALID-001

**Priority**: MANDATORY
**Applies to**: All implementation plans in Architect Mode

## Rule

Every implementation plan MUST define validation commands as Phase 1, before any implementation begins.

### Validation-First Principle

For Nix configuration changes, "testing" means **validation** — proving the configuration is syntactically correct, builds successfully, and applies without errors.

### Required Validation Definitions

Every implementation plan must specify:

1. **Syntax validation**: Which `nix flake check` command to run
2. **Build validation**: Which `nixos-rebuild build` / `darwin-rebuild build` commands to run (per affected host)
3. **Apply validation**: Which `nixos-rebuild test` / `darwin-rebuild check` commands to verify before `switch`
4. **Rollback path**: How to revert if the change causes issues

### Plan Structure

```
Phase 0: Validation Strategy (BEFORE implementation)
  - List all validation commands
  - Identify affected hosts
  - Define rollback procedure
  - Identify dangerous changes (bootloader, networking, filesystems)

Phase 1..N: Implementation Steps
  - Each step includes its validation command
  - Dangerous changes require explicit user approval

Final Phase: Apply & Verify
  - Apply configuration
  - Verify services/state
  - Document any manual post-apply steps
```

### Dangerous Change Categories

These changes require explicit warnings and rollback paths in the plan:

| Category | Examples | Risk |
|----------|----------|------|
| Boot | Bootloader, kernel, initrd changes | System may not boot |
| Network | Firewall, interfaces, WireGuard, DNS | Remote access loss |
| Filesystem | Disko, mount points, impermanence paths | Data loss |
| Authentication | SSH keys, sudo, PAM, user accounts | Lockout |
| Secrets | sops-nix key rotation, age key changes | Decryption failure |

### Anti-Pattern

Do NOT plan "write tests first" for Nix configuration. There are no unit tests for `.nix` files. Instead, define the validation commands that prove the configuration works.

## Enforcement

- Plans without Phase 0 (Validation Strategy) = rule violation
- Plans without rollback paths for dangerous changes = rule violation
- Plans that reference "unit tests" or "BDD tests" for Nix configs = rule violation
