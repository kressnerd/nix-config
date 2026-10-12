# 2. Architecture Constraints

Constraints that limit design freedom. Each entry is evidenced by a source file
or an accepted process rule, not by preference.

## Technical constraints

| Constraint | Motivation / evidence |
|---|---|
| The repository is a single Nix flake; all host configuration must be expressible as NixOS/nix-darwin/Home Manager modules. | `flake.nix` is the only entry point; `nix flake check` is the validation gate. There is no runtime language in which to put imperative setup outside Nix. |
| The stable channel is `nixos-26.05`, pinned with flake inputs. | `flake.nix` input `nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"`; `nixpkgs-unstable` and `nixpkgs-darwin` are separate inputs. `tests/unit/flake-channel-test.nix` asserts `lib.trivial.release == "26.05"`. |
| Packages that exist only in unstable must be consumed through the `pkgs-unstable` shim, not by moving a host to unstable wholesale. | `lib/helpers.nix` `mkPkgsUnstable`; passed via `extraSpecialArgs` in every configuration. |
| The secret store is SOPS with age; a host decrypts only secrets it is a recipient for. | `sops-nix` input, `.sops.yaml` `creation_rules` per `hosts/<host>/secrets.yaml`, `sops.` options in host/user modules. |
| Host user configuration is Home Manager only; there is no per-host manual shell state. | Every host maps to exactly one `home/dan/<host>.nix` via the flake's `home-manager.users`. |
| Impermanent hosts wipe their root filesystem on boot; persistent state must be declared. | `hosts/thiniel/default.nix` (systemd initrd rollback), `hosts/adlerkopf/impermanence.nix` (btrfs `@root` reset); `environment.persistence` / `myHome.persistence`. |
| Disk layouts on provisioned hosts are declarative (`disko`); a host is installed from a flake, not hand-partitioned. | `disko.nixosModules.disko` in the flake; `hosts/{nixos-vm-minimal,cupix001,adlerkopf}/disko.nix`. |
| thiniel's boot-time root wipe currently depends on the systemd initrd implementation; the previous scripted-stage-1 form is removed in nixpkgs 26.11. | Comment in `hosts/thiniel/default.nix`; guarded by `tests/assertions/thiniel-boot-invariants.nix`. This is a dated migration obligation, tracked in [chapter 11](11-risks-and-technical-debt.md). |
| The `adlerkopf` build depends on a non-committed `private.nix`; `nix build`/`nix flake check` for that host fails without it. | `hosts/adlerkopf/private.nix.example` (gathering instructions), README "Host Setup". |

## Organisational constraints

| Constraint | Motivation / evidence |
|---|---|
| Single-operator repository; the owner/operator holds sole administrative authority. | Ideation personas; `users.users.dan` is the only administrative user on every host. |
| Every configuration change follows Red-Green-Refactor with one minimal change per cycle, and the RED must be observed failing. | `CLAUDE.md` "Test-First Workflow (MANDATORY)"; `AGENTS.md` "Test-First Delegation Sequence". |
| Every scenario in a change delta carries exactly one binding tag that resolves to a native target; `@e2e` scenarios must bind to a VM/host/deploy target. | `docs/GIVN-VERIFICATION.md` "Binding tags"; enforced by `scripts/givn-spec-trace.py` in the `tasks` and `review` hooks (`givn/config.yaml`). |
| The project does not use a Gherkin/Cucumber step runner; Gherkin files are the specification, the native target is the executable. | `docs/GIVN-VERIFICATION.md` "Why this is not the default givn model". |
| Agents must never call `sops`, `age`, or `ssh-to-age`, and must never read a decrypted secret. Decryption and editing are human-only. | `CLAUDE.md` "Safety Rules → Secrets"; the guard hook `home/dan/features/development/omp.nix` installs a secret-access guard for the `omp` agent. |
| Architecture decisions are recorded as MADR files only when they pass the five-dimension qualification gate; otherwise they are routed once to their canonical artifact. | [`docs/arc42/README.md`](README.md), the ADR template [`docs/arc42/adr/adr-template.md`](adr/adr-template.md), and the resolved `arc42-docs` addon instruction; see [chapter 9](09-architecture-decisions.md). |
| Implementation or process decisions live with their owning artifact (spec, `design.md`, arc42 chapter, process doc), not duplicated into an ADR. | Same qualification gate (`lower_level_artifact` dimension). |

## Conventions

| Convention | Motivation / evidence |
|---|---|
| Directory layout: `hosts/<host>/` (system), `home/dan/features/<category>/` (user features), `modules/<kind>/<concern>/` (reusable options+default), `tests/{unit,assertions,integration}/`, `scripts/`. | Observed layout; documented in `docs/ARCHITECTURE.md` and `CLAUDE.md`. |
| Each host states device-specific values through typed options (`myHome.*`, `mySystem.*`, `networking.<host>.*`) which shared modules read; shared modules do not branch on host name. | `modules/home-manager/ssh/options.nix`, `modules/{nixos,home-manager}/persistence/options.nix`; the rationale is recorded in the change design `givn/changes/host-specific-ssh-identities/design.md`. |
| Feature modules are grouped by concern category (`cli`, `development`, `linux`, `macos`, `productivity`) and imported explicitly per user profile — there is no auto-discovery. | `home/dan/<host>.nix` import lists (27 imports on the Mac, 41 on thiniel, 1 on `adlerkopf`/`cupix001`). |
| Platform differences are declared with `lib.optionals`/`lib.optionalAttrs` on `pkgs.stdenv.hostPlatform.isDarwin`/`isLinux`, never by duplicating a module. | e.g. `features/cli/kitty.nix`, `features/cli/ssh.nix`, `features/productivity/browser.nix`. |
| Nix files are formatted with `nixfmt`; `deadnix` and `statix` must pass. | `flake.nix` formatter + `lint-deadnix`/`lint-statix`/`lint-nixfmt` checks; `AGENTS.md` "EDIT → CHECK → FORMAT → APPLY". |
| `stateVersion` (system and home) is set once and never changed. | `CLAUDE.md` "Immutable Values"; every host uses `25.11`, Darwin uses `system.stateVersion = 6`. |
| Secrets are declared under `sops.secrets` in the host/user module and consumed through `config.sops.placeholder` in `sops.templates` or `lib.optionalAttrs (config.sops.secrets ? "<key>")`. | `CLAUDE.md` "SOPS Secrets Flow"; `home/dan/features/cli/git.nix`, `features/cli/ssh.nix`. |
| Documentation that describes the fleet must state evidence status and must not present planned capabilities as implemented. | This arc42 set; the constraint is the reason [chapter 1](01-introduction-and-goals.md) carries an evidence legend. |
