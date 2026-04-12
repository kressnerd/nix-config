# Epic 1 Architecture Review — cupix001

**Date**: 2026-04-12
**Status**: COMPLETE
**Scope**: Post-foundation design review — 9 architecture/design questions

## Summary

cupix001 is a hardened edge ingress gateway on a netcup KVM VPS. Epic 1 (Foundation) registered the host skeleton in the flake. This review evaluates 9 design concerns raised during the foundation phase and classifies each as **OK as-is**, **Improve now** (before Epic 2), or **Improve later** (tracked TODO).

## Classification Overview

| # | Topic | Verdict |
|---|-------|---------|
| Q1 | pkgs-unstable on edge gateway | **Improve later** (Epic 9) |
| Q2 | helpers.nix Firefox imports | **OK as-is** |
| Q3 | allowUnfree on server | **Improve later** (Epic 9) |
| Q4 | Home Manager on server | **OK as-is** (with caveat) |
| Q5 | htop from HM global | **OK as-is** |
| Q6 | NetworkManager in common/global | **Improve now** |
| Q7 | Boot mode UEFI vs GRUB | **Improve now** |
| Q8 | options.nix network structure leak | **OK as-is** |
| Q9 | Tests imported in default.nix | **OK as-is** |

---

## Q1: pkgs-unstable for an edge gateway

**Verdict: Improve later** — Epic 9 (Minimal Profile)

### Analysis

`pkgs-unstable` is passed via `specialArgs` and HM `extraSpecialArgs` in [`flake.nix`](../../../flake.nix:179). Currently, nothing in [`home/dan/cupix001.nix`](../../../home/dan/cupix001.nix) or [`hosts/cupix001/default.nix`](../../../hosts/cupix001/default.nix) actually references `pkgs-unstable`. It is available but unused.

**Risk**: The mere availability of `pkgs-unstable` in `specialArgs` does not cause any packages from unstable to be installed. Unstable packages only enter the closure when explicitly referenced as `pkgs-unstable.<pkg>`. At this point, there is zero security impact because nothing uses it.

**Benefit of keeping it**: Some future services (e.g., Caddy with specific plugins, DERP relay) may only be available or sufficiently recent on unstable. Removing it now would require re-adding it later.

**Recommendation**: Keep `pkgs-unstable` available in `specialArgs` for now. In Epic 9 (Minimal Profile), audit the final closure: if nothing references `pkgs-unstable`, remove it from the cupix001 configuration block. If specific packages do use it, document the justification per package.

### Action

- None now. Track for Epic 9 closure audit.

---

## Q2: helpers.nix Firefox imports

**Verdict: OK as-is**

### Analysis

[`lib/helpers.nix`](../../../lib/helpers.nix) is an attribute set with two keys: `mkPkgsUnstable` and `mkFirefoxExtensions`. The cupix001 flake block calls `(import ./lib/helpers.nix).mkPkgsUnstable { ... }`.

**Key insight**: Nix is lazily evaluated. `import ./lib/helpers.nix` evaluates to the full attribute set, but only the accessed attribute (`mkPkgsUnstable`) is evaluated. `mkFirefoxExtensions` is a function that takes `{ addons }` — it is never called, so its body is never evaluated. There is:

- **No evaluation overhead**: the function body of `mkFirefoxExtensions` is never forced
- **No dependency pollution**: Firefox addons are not pulled into the closure
- **No store path impact**: nothing from NUR firefox-addons reaches the cupix001 build

The file is small (50 lines) and splitting it would add complexity without benefit.

### Action

- None.

---

## Q3: Unfree packages on server

**Verdict: Improve later** — Epic 9 (Minimal Profile)

### Analysis

`nixpkgs.config.allowUnfree = true` is set in two places for cupix001:

1. [`hosts/common/global/default.nix`](../../../hosts/common/global/default.nix:6) — shared across all hosts
2. [`flake.nix`](../../../flake.nix:194) — inline module in the cupix001 config block

Both are active. Currently, cupix001 installs zero unfree packages. The flag has no effect on the closure contents — it only permits evaluation of unfree packages if referenced.

**Security/audit implication**: For a hardened server, `allowUnfree = false` would act as a guardrail preventing accidental introduction of proprietary software with unknown security properties. However, this is a low-priority concern because:

- No unfree packages are currently referenced
- The flag is a predicate, not a package list
- Changing it now risks breaking `nix flake check` if any transitive dependency triggers the unfree check

**Recommendation**: In Epic 9 (Minimal Profile), set `nixpkgs.config.allowUnfree = lib.mkForce false;` in the cupix001 host config, verify `nix flake check` still passes, and document the decision. If specific unfree packages are needed later, use per-package `allowUnfreePredicate` instead.

### Action

- None now. Track for Epic 9.

---

## Q4: Home Manager on a server

**Verdict: OK as-is** (with caveat on `pkgs-unstable` — see Q1)

### Analysis

HM is configured for cupix001 in [`flake.nix`](../../../flake.nix:198) with `useGlobalPkgs = true`, `useUserPackages = true`, and the profile [`home/dan/cupix001.nix`](../../../home/dan/cupix001.nix).

The HM profile is minimal: it imports `global/default.nix` (sets `stateVersion`, `htop`, `programs.home-manager.enable`) and sets `home.username`/`home.homeDirectory`.

**HM on a server is appropriate because**:

- It manages the `dan` user's environment declaratively (shell config, git, SSH keys)
- Future epics will add CLI features (vim, git, shell-utils) to the server user profile
- Without HM, user-level configuration would require imperative setup or NixOS-level workarounds
- The overhead is negligible: HM evaluation adds minimal build time and no runtime services

**The minimal useful HM configuration** for a server is exactly what exists: `stateVersion` + `home-manager.enable` + a monitoring tool. Additional CLI features will be composed via `features/cli/` imports as needed in later epics.

**`pkgs-unstable` in `extraSpecialArgs`**: same analysis as Q1 — available but unused, no impact. Track removal in Epic 9.

### Action

- None.

---

## Q5: htop from HM global

**Verdict: OK as-is**

### Analysis

[`home/dan/global/default.nix`](../../../home/dan/global/default.nix:9) installs `htop` via `home.packages`. htop is a diagnostic tool, not a service. It:

- Has minimal attack surface (read-only process monitoring, no network listeners, no setuid)
- Is essential for server diagnosis (CPU, memory, process monitoring)
- Adds ~2 MB to the closure
- Is universally expected on any administered Linux system

**Should HM global be split into desktop/server variants?** Not at this point. The current global contains only `stateVersion`, `htop`, and `programs.home-manager.enable` — all three are appropriate for every host type. Splitting would be warranted only when desktop-specific packages or settings creep into global. Currently, nothing in global is desktop-only.

**Monitor**: If future changes add desktop packages to `global/default.nix`, that is the trigger to split into `global/default.nix` (universal) + `global/desktop.nix` (desktop-only). The server profile would import only the universal baseline.

### Action

- None. Monitor for desktop-only additions to global.

---

## Q6: NetworkManager in common/global

**Verdict: Improve now** — before Epic 2

### Analysis

[`hosts/common/global/default.nix`](../../../hosts/common/global/default.nix:9) sets `networking.networkmanager.enable = true`. cupix001 overrides this with [`lib.mkForce false`](../../../hosts/cupix001/default.nix:22).

**Problems with this pattern**:

1. **`mkForce` is a code smell**: it signals a design issue where the default is wrong for some consumers. The common module should not assume all hosts use NetworkManager.
2. **`networkmanager` group in `dan.nix`**: [`hosts/common/users/dan.nix`](../../../hosts/common/users/dan.nix:8) adds `dan` to the `networkmanager` group unconditionally. On cupix001 where NM is disabled, this group membership is harmless but misleading.
3. **Assertion validates the override**: the test in [`cupix001-invariants.nix`](../../../tests/assertions/cupix001-invariants.nix:17) asserts NM is disabled, which correctly catches regressions — but the assertion exists because of the bad default.
4. **Every future server host** would need the same `mkForce` override, violating DRY.

**Recommended refactor**: Move `networking.networkmanager.enable = true` out of `common/global` and into an optional module or directly into desktop host configs. Server hosts use `systemd-networkd` or static config — they should not need to override a desktop default.

### Action Items (before Epic 2)

1. **Remove** `networking.networkmanager.enable = true;` from `hosts/common/global/default.nix`
2. **Create** `hosts/common/optional/networkmanager.nix` with NM enable + configuration
3. **Import** `../common/optional/networkmanager.nix` in desktop hosts (thiniel, VMs that need NM)
4. **Remove** `networking.networkmanager.enable = lib.mkForce false;` from `hosts/cupix001/default.nix`
5. **Consider** making `extraGroups` in `hosts/common/users/dan.nix` conditional: only include `networkmanager` when NM is enabled (use `lib.mkIf config.networking.networkmanager.enable`)
6. **Verify**: `nix flake check` — all assertions must still pass

---

## Q7: Boot mode is UEFI

**Verdict: Improve now** — before Epic 2 (Disk Layout)

### Analysis

[`hosts/cupix001/hardware.nix`](../../../hosts/cupix001/hardware.nix:5) configures GRUB with `boot.loader.grub.enable = true` and `devices = ["/dev/vda"]`. The comment on line 2 states: *Boot mode determined in prerequisites step 2; update to systemd-boot if UEFI*.

The user confirms the VPS uses UEFI boot. The disko plan (Epic 2) must configure an EFI System Partition (ESP). The bootloader configuration must switch from GRUB/BIOS to either:

- **systemd-boot** (preferred for UEFI on NixOS — simpler, well-tested)
- **GRUB with EFI** (if specific GRUB features are needed — unlikely for a VPS)

**Recommendation**: Use `systemd-boot` — it is the standard NixOS UEFI bootloader, simpler to configure, and has no disadvantages on a VPS.

### Action Items (before/during Epic 2)

1. **Update** `hosts/cupix001/hardware.nix` — replace GRUB block with:
   ```nix
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;
   ```
2. **Ensure** the disko plan (`02-disk-layout.md`) includes an ESP partition (type `EF00`, FAT32, mounted at `/boot`)
3. **Remove** GRUB placeholder `devices` and filesystem entries (disko will manage these)
4. **Verify**: `nix flake check` passes after the change

**Note**: The placeholder `fileSystems."/"` and `swapDevices` in `hardware.nix` will be replaced by disko in Epic 2. The bootloader change should be done as part of that epic since both touch `hardware.nix`.

---

## Q8: options.nix — network structure leak

**Verdict: OK as-is**

### Analysis

[`hosts/cupix001/options.nix`](../../../hosts/cupix001/options.nix) declares typed options under `networking.cupix001.*`: `publicIPv4`, `publicIPv6`, `gateway4`, `gateway6`, `dns`, `wgListenPort`, `wgTunnelIPv4`, `wgPeerTunnelIPv4`, `enablePublicSSH`, `sshBootstrapPort`, `interfaceName`.

The option names (types + descriptions) are in the public repo. The actual values come from `private.nix` (gitignored, loaded conditionally via `lib.optional (builtins.pathExists ./private.nix)`).

**Does this reveal too much?**

No. This is standard infrastructure-as-code practice:

1. **Schema ≠ data**: The option declarations are a schema — they describe what configuration the host accepts, not what values it uses. Knowing that a server has a public IPv4 address and a WireGuard tunnel is architecturally obvious for any edge gateway.
2. **Industry precedent**: Terraform, Ansible, Pulumi all publish variable declarations (schemas) in public repos while keeping `.tfvars`, `vault` secrets, and inventory files private. The NixOS module option pattern follows the same principle.
3. **No exploitable information**: The option names reveal the host has IPv4/v6, WireGuard, and SSH — all of which are detectable via network scanning anyway. The sensitive data (actual IPs, ports, keys) remains in `private.nix` and `secrets.yaml`.
4. **WireGuard default port**: `wgListenPort` has `default = 51820` (the well-known WireGuard port). This is not a secret — WireGuard is designed to be resistant to port scanning (silent to unauthenticated packets).
5. **`sshBootstrapPort` default 55809**: This reveals the intended non-standard SSH port. Minor information leak, but security-through-obscurity via port numbers provides negligible protection. The real SSH hardening happens via key-only auth, fail2ban, and firewall rules.

**One minor improvement** (not blocking): The `sshBootstrapPort` default could be moved to `private.nix` to avoid revealing the chosen port. This is cosmetic — the port is trivially discoverable via scanning.

### Action

- None required. Optionally move `sshBootstrapPort` default to `private.nix` in a future cleanup pass.

---

## Q9: Tests imported in default.nix

**Verdict: OK as-is**

### Analysis

[`hosts/cupix001/default.nix`](../../../hosts/cupix001/default.nix:14) imports `../../tests/assertions`. From an application development perspective, this looks like mixing test code with production code. In NixOS, this pattern is fundamentally correct and intentional.

**Why NixOS assertions are different from application tests**:

1. **Assertions are not tests — they are invariants**. NixOS `assertions` are module-level constraints evaluated at configuration build time (`nix flake check`, `nixos-rebuild build`). They are analogous to database constraints or type system checks, not unit tests. They prevent invalid configurations from being built.

2. **They run at evaluation time, not runtime**. Application tests execute after the application is built and deployed. NixOS assertions fire during Nix evaluation — if an assertion fails, no system closure is produced. This is a compile-time check, not a runtime test.

3. **They are NixOS modules, not test harnesses**. The assertion files (e.g., [`cupix001-invariants.nix`](../../../tests/assertions/cupix001-invariants.nix)) are NixOS modules that contribute `config.assertions` — the same mechanism used by upstream NixOS modules to validate option combinations. Importing them is identical to importing any other NixOS module.

4. **They must be imported to function**. Unlike application tests that are discovered by a test runner, NixOS assertions only fire if they are part of the module evaluation graph. If not imported in `default.nix`, they would not be evaluated during `nix flake check`.

5. **Host-guarded assertions prevent cross-host interference**. Each host-specific assertion file uses `lib.mkIf (config.networking.hostName == "cupix001")` to ensure assertions only fire for the correct host. The shared `tests/assertions/default.nix` aggregates all assertion modules, and each host safely imports the full set.

6. **This is the established NixOS pattern**. The NixOS module system itself uses assertions extensively — `services.openssh` asserts valid key types, `networking.firewall` asserts valid port ranges, etc. User-defined assertions follow the same mechanism.

**Analogy**: Importing `tests/assertions` in `default.nix` is like enabling `CHECK` constraints in a database schema definition. The constraints are part of the schema, not separate test files.

### Action

- None. The pattern is correct and idiomatic.

---

## Action Summary

### Improve Now (before Epic 2)

| # | Action | File(s) | Verification |
|---|--------|---------|--------------|
| 1 | Remove `networking.networkmanager.enable = true` from common/global | `hosts/common/global/default.nix` | `nix flake check` |
| 2 | Create `hosts/common/optional/networkmanager.nix` with NM config | New file | `nix flake check` |
| 3 | Import NM optional module in desktop hosts | Desktop host `default.nix` files | `nix flake check` |
| 4 | Remove `mkForce false` NM override from cupix001 | `hosts/cupix001/default.nix` | `nix flake check` |
| 5 | Make `networkmanager` group conditional in dan.nix | `hosts/common/users/dan.nix` | `nix flake check` |
| 6 | Switch hardware.nix from GRUB to systemd-boot | `hosts/cupix001/hardware.nix` | `nix flake check` |

### Improve Later

| # | Topic | Target Epic | Action |
|---|-------|-------------|--------|
| 1 | Remove `pkgs-unstable` if unused | Epic 9 (Minimal Profile) | Audit final closure, remove if no references |
| 2 | Set `allowUnfree = false` for cupix001 | Epic 9 (Minimal Profile) | Override with `mkForce false`, verify check passes |
| 3 | Move `sshBootstrapPort` default to private.nix | Any future cleanup | Cosmetic — optional |

### OK As-Is (no action)

- Q2: `helpers.nix` Firefox imports — lazy evaluation, no impact
- Q4: Home Manager on server — appropriate, minimal config
- Q5: htop from HM global — essential diagnostic tool, universal
- Q8: options.nix schema — standard IaC pattern, values are private
- Q9: Assertions in default.nix — correct NixOS idiom
