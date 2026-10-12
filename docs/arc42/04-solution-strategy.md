# 4. Solution Strategy

The fundamental choices that shape the whole configuration. Rationale lives
with its owning artifact; this chapter states the choices and points to the
evidence. One choice here — operational-data separation — qualifies as an ADR
([ADR-0001](adr/ADR-0001-private-data-strategy.md)); the others do not, see
[chapter 9](09-architecture-decisions.md).

## Key decisions

1. **One flake, many hosts.** `flake.nix` is the single entry point producing
   four `nixosConfigurations` and one `darwinConfigurations`; every host is a
   thin system module plus one Home Manager user profile. Deployment is
   generation-based and therefore reversible per host.
2. **Dual channel with an unstable shim.** The stable channel is `nixos-26.05`.
   Unstable packages are consumed through `pkgs-unstable` (`lib/helpers.nix`)
   rather than by moving a host wholesale; the Darwin host additionally has its
   own `nixpkgs-darwin` input. This keeps the default package set on stable
   while allowing specific tools (hyprland, claude-code, omp, vscode.fhs) to
   follow unstable.
3. **Layered composition.** `hosts/common` (shared NixOS base) → host options
   (`networking.<host>.*`, `mySystem.persistence`, `adlerkopf.vmMode`) → the
   host's own modules → the Home Manager profile → feature modules. Shared
   feature modules read typed options and never branch on a host name; device
   differences are declared per host. Rationale and the worked example are in
   `givn/changes/host-specific-ssh-identities/design.md`.
4. **Impermanence with declared persistence.** Stateful hosts wipe their root
   filesystem on boot and bind declared paths from `/persist`. thiniel wipes and
   recreates the btrfs root subvolume in a systemd initrd service; adlerkopf
   resets `@root` from the `@root-blank` snapshot. Persistence lists are
   explicit, split between a system layer (`mySystem.persistence`, base paths)
   and a Home Manager layer (`myHome.persistence`, user paths).
5. **SOPS-nix with per-host age recipients.** Secret files are YAML encrypted
   to age recipients listed in `.sops.yaml`; a host decrypts only what it is a
   recipient for. Where practical the host's age key is derived from its SSH
   host key (adlerkopf, cupix001 `age.sshKeyPaths`), so no extra bootstrap key
   has to survive installation.
6. **Native verification, no step runner.** Gherkin deltas are the
   specification; the executable is the native target (`@check:` flake check,
   `@host:` host evaluation firing module assertions, `@e2e` VM/host).
   `scripts/givn-spec-trace.py` enforces exactly one binding per scenario and
   replaces a coverage metric. Policy owner: `docs/GIVN-VERIFICATION.md`.
7. **Declarative provisioning and boot integrity for servers.** `disko` lays
   out disks, `lanzaboote` signs a Unified Kernel Image for Secure Boot, and
   LUKS is unlocked by TPM2 with a passphrase fallback. This is what makes a
   headless host deployable and recoverable (runbook:
   `docs/ADLERKOPF-DEPLOY-RUNBOOK.md`).
8. **Consumer product surface stays external.** The repository configures
   qualified hosted applications and the infrastructure around them; it does
   not build application features. This is a confirmed boundary from ideation
   and is **not yet implemented** for any application.
9. **Operational-data separation.** The public repository holds the option
   schema and documentation-range defaults; a host's real values reach it only
   through the overridable `private` flake input, whose public default is an
   in-tree stub. A guard refuses any revision that would record an operational
   value, a per-host private-value file, or an unencrypted secret. Owner:
   [ADR-0001](adr/ADR-0001-private-data-strategy.md); the concept is in
   [chapter 8](08-crosscutting-concepts.md).

## Technology choices

| Concern | Choice | Rationale (owner) |
|---|---|---|
| Configuration language / build | Nix flakes | Reproducible, pinned inputs; `flake.nix`, `flake.lock` |
| Linux system management | NixOS modules | Declarative system state; `hosts/*` |
| macOS system management | nix-darwin + `nix-homebrew` + `mac-app-util` | Declarative macOS defaults, Homebrew casks, app linking (`hosts/J6G6Y9JK7L/default.nix`) |
| User environment | Home Manager feature modules | Cross-platform user surface; `home/dan/**` |
| Theming | `stylix` (One Light, `autoEnable = false`) | System-wide palette with hand-crafted per-target themes; `hosts/thiniel`, `hosts/J6G6Y9JK7L` |
| Secrets | `sops-nix` + age | Encrypted at rest, host-scoped decryption; `.sops.yaml` |
| Disk layout | `disko` | Declarative partitioning/formatting; `hosts/*/disko.nix` |
| Persistence model | `impermanence` + custom persistence modules | Explicit, reviewable persistence; `modules/*/persistence` |
| Secure Boot / UKI | `lanzaboote` (adlerkopf) | Verified boot chain on the server; `hosts/adlerkopf/secure-boot.nix` |
| Remote installation | `nixos-anywhere` (input + `scripts/`) | Install a host from a workstation, not from a console |
| Fleet deployment | Colmena (input + dev shell) | **Declared, currently unused** — `colmenaHive` has zero nodes |
| Git identity isolation | Per-identity SSH keys + SSH-host aliases + `includeIf` | A device presents only the identity it declares; `features/cli/{git,ssh}.nix` |
| Edge DNS filtering | AdGuard Home (adlerkopf) | **Declared** on one host only; `hosts/adlerkopf/services/adguard.nix` |
| Edge firewall management | netcup SCP external firewall via Python CLI | The VPS firewall is managed account-side, not on the host; `scripts/netcup_firewall.py` |
| Specification workflow | `givn` with native bindings | Specs stay executable without a step runner; `givn/`, `docs/GIVN-VERIFICATION.md` |
| Private operational values | Overridable `private` flake input with an in-tree stub default | The `git+file://` source rule forbids a gitignored file; the input is visible and overridable; [ADR-0001](adr/ADR-0001-private-data-strategy.md) |

## Approach to quality goals

| Quality attribute (ch. 1) | Approach |
|---|---|
| Reproducibility | Everything is a flake with pinned inputs; the only build gate is `nix flake check`; lint/format checks (`deadnix`, `statix`, `nixfmt`) are part of the same gate. |
| Security of access material | Identity selection derives from per-host declarations and is fail-closed; secrets are age-encrypted with per-host recipients; SSH is key-only on servers; agents are forbidden to decrypt. |
| Recoverability / auditability | One commit per scenario, givn attribution hooks, binding tags resolved by `scripts/givn-spec-trace.py`, and generation-level rollback per host. |
| Boot determinism | Root wipe on boot plus explicit persistence lists; assertions (`thiniel-boot-invariants`, `thiniel-impermanence-invariants`, `adlerkopf-invariants`) guard the model at evaluation time. |
| Operational safety | TPM2 unlock and `lanzaboote` Secure Boot on adlerkopf; `security.sudo.wheelNeedsPassword = false` for non-interactive remote rebuilds; the deployment runbook documents bootstrap and rollback. |

### Open strategy questions (not settled)

These are **not** implemented choices; they are recorded unresolved inputs from
ideation and the working tree. They are stated here so the baseline does not
imply a settled design.

- Whether an edge ingress tier (`Caddy` forward-auth, WireGuard, derper,
  CrowdSec, nftables, Authentik) is built on the VPS: it is a confirmed future
  effort, not abandoned. The design document [`docs/edge-all.md`](../edge-all.md)
  and the cupix001 plan set describe it, and it is sequenced **after** the
  private-data remediation that must precede a public GitHub release
  ([`docs/plans/private-data-remediation-plan.md`](../plans/private-data-remediation-plan.md),
  now the change `private-data-remediation`). The working tree contains none of
  the ingress tier.
- Which application supplies album sharing, document editing, or calendar
  (open input Q17).
- Which personal state/identity sources constitute the usable-work baseline
  (open input Q16).
- Whether backup runs on adlerkopf (restic plan, no target confirmed),
  thiniel (explicitly deferred), or elsewhere.
