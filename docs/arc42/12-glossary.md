# 12. Glossary

Terms used consistently across this documentation. Alphabetically ordered.
Candidate terms from the ideation topic are marked as such and are not part of
the implemented architecture.

| Term | Definition |
|---|---|
| Assertion (`config.assertions`) | An evaluation-time check declared by a module (`tests/assertions/*-invariants.nix`). The host configuration fails to evaluate if it does not hold. |
| Binding tag | The single `@check:<name>`, `@host:<name>`, or `@deploy:<name>` tag a scenario carries to name the native target that proves it (`docs/GIVN-VERIFICATION.md`). |
| Check (flake `checks`) | A derivation exposed by the flake: `unit-helpers`, `lint-deadnix`, `lint-statix`, `lint-nixfmt` on all systems; `integration-vm-minimal-ssh`, `integration-adlerkopf`, `integration-ssh-identity-selection` on Linux. |
| Colmena hive | The `colmenaHive` flake output intended for coordinated fleet deployment. Currently declared with **zero** nodes. |
| Connection entry | The SSH client configuration entry (host block) a device renders for one identity, naming that identity's file. |
| Declared | Evidence label: the Nix source states it and it is rendered into a configuration. It is not proof of live behaviour. |
| disko | Declarative disk partitioning/formatting module used for the hosts that are installed from the flake. |
| Feature module | A Home Manager module under `home/dan/features/<category>/` that renders one concern (tool, service, desktop component) from host declarations, platform conditionals, and declared secrets. |
| Flake | The repository's single Nix entry point (`flake.nix` + `flake.lock`) that declares all host configurations and outputs. |
| Generation | One built and activatable system or home profile revision. Rollback is selection of an older generation. |
| Home profile | The Home Manager configuration of one host user (`home/dan/<host>.nix`). |
| Host | One declared machine configuration under `hosts/<host>/` mapped in the flake to a `nixosConfiguration` or `darwinConfiguration`. |
| Identity declaration | A host's statement of which identity material that device holds (`myHome.ssh`), from which the connection entries and the workspace identity configuration are rendered. |
| Identity file | The private key file a device presents to authenticate to a remote Git host. |
| Identity material | The private keys a device holds for the identities it uses; a device declares it, and a connection entry is rendered only where the device declares the material for that identity. |
| Impermanence | The model in which a stateful host's root filesystem is reset on every boot and only explicitly declared paths survive. |
| Intended | Evidence label: an accepted requirement or confirmed decision that is **not** implemented in the working tree. |
| `mkPkgsUnstable` | Helper in `lib/helpers.nix` that builds the unstable package set (`pkgs-unstable`) injected into host configurations. |
| `myHome.*` | The reusable Home Manager option namespace declared under `modules/home-manager/*` and filled by a host profile (`myHome.ssh`, `myHome.persistence`). |
| `mySystem.*` | The reusable NixOS option namespace declared under `modules/nixos/*` and filled by a host module (`mySystem.persistence`). |
| `@e2e` | Tag marking a scenario that must bind to a real boot (VM) or a host confirmed on hardware, never to a plain unit/lint check. |
| netcup SCP | The netcup Server Control Panel, whose external firewall is managed account-side by `scripts/netcup_firewall.py`. |
| Option module | A pair `modules/<kind>/<concern>/options.nix` + `default.nix` that declares a typed surface and renders its behaviour. |
| Personal identity | The device owner's own identity on a device: its private key and the connection and workspace surfaces derived from that key. |
| Persistence | The declared set of paths bound from the persistent volume to survive a root wipe. Split into a system layer (`mySystem.persistence`) and a user layer (`myHome.persistence`). |
| Private workspace | The workspace directory whose Git operations use the device's personal identity, selected by the host's include rule. |
| RED/GREEN/REFACTOR | The mandatory per-change loop: the bound target must be observed failing before the configuration change and passing after it. |
| SOPS / age | The secret scheme: SOPS-encrypted YAML files whose recipients are age keys, mapped per host file in `.sops.yaml`. |
| stylix | The theming module supplying the system-wide palette (One Light) with per-target opt-in. |
| Success guarantee (ideation) | The standalone outcome a change seed promises; a seed is input to a future proposal, not an implemented capability. |
| thiniel / adlerkopf / cupix001 / nixos-vm-minimal / J6G6Y9JK7L | The five declared host identities: Linux laptop, home server, netcup VPS (planned edge ingress gateway, still a skeleton), minimal test VM, and work macOS workstation. |
| Verified | Evidence label: a native target reproduced the behaviour (host evaluation, assertion, unit test, or booted QEMU VM). |
| Work identity | An employer or client identity, with its own key and connection entry, declared only on a device that holds that identity's material. |

## Candidate terms (not promoted)

The ideation topic "Growing personal and family infrastructure" records seven
**candidate** domain terms that remain topic-local and unpromoted; the durable
glossary above deliberately does not include them. Nothing in the working tree
confirms them as implemented concepts. The topic record itself is the authority:
[`givn/ideation/infrastructure-growth/domain-terms.md`](../../givn/ideation/infrastructure-growth/domain-terms.md).
