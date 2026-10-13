# 8. Cross-cutting Concepts

Concepts, principles and patterns that recur across this repository. Each is
stated with the rationale that makes it non-obvious, plus its failure mode and
its verification.

## Per-host identity declaration

A device presents only the identity material it holds, and it states that
material in one place: the host user module declares the private key of its
personal identity (`myHome.ssh.personalIdentityFile`) and the manually
maintained `ssh_config` files it keeps (`myHome.ssh.includedConfigs`) —
`modules/home-manager/ssh/options.nix`.

Shared feature modules render from that declaration: the SSH feature renders the
personal connection entry and the workspace identity configuration from the
declared key path, and renders a work identity entry only where the host
declares that identity's secret material. Device and platform differences are
therefore declared per host, never branched on the platform inside a shared
feature, and no device inherits another device's identity surface.

Rationale: two devices that belong to the same owner do not hold the same keys
or the same work relationships. A shared feature module that hardcodes one
device's key paths fails closed on the other device — access is denied with no
usable key — while hiding which key the device was supposed to present.

Failure mode: an identity file path is a declaration, not a guarantee. Nothing in
the configuration checks that the file exists; the declaration is proven on the
device (`ssh -G <connection>`) after activation, and its failure mode is
fail-closed (no key presented).

Verification: host declarations and the rendered result are asserted at
evaluation time in `tests/assertions/thiniel-invariants.nix` and
`tests/assertions/J6G6Y9JK7L-invariants.nix`, and the end-to-end behaviour is
proven by the QEMU VM check
`tests/integration/ssh-identity-selection-test.nix`.

## Operational-data separation

The public repository holds the option schema and documentation-range defaults;
the operator's real operational values — addresses, gateway, hardware address,
resolvers, ports — reach a host only through the overridable `private` flake
input. The public flake's default for that input is the in-tree stub
`private-stub/flake.nix`, so a clean clone and CI evaluate with placeholders and
need no private access; the operator's deploy commands replace it with
`--override-input private git+file:///home/dan/dev/PRIVATE/nix-private`.

Rationale: when a flake lives in a git worktree, the evaluator reads a
`git+file://` source that only sees the git index, so a gitignored `private.nix`
is invisible and every host build fails once it is untracked. The values
therefore cannot come from a file in the public repository; they come from an
input the evaluator can see and the operator can override. The full comparison
and the rejected alternatives are in
[ADR-0001](adr/ADR-0001-private-data-strategy.md).

Three rules hold the boundary: the recorded content and the published history
carry no operational value; the public fallback stays non-operational, which the
stub enforces by asserting the host defaults are documentation-range
placeholders; and a guard refuses any revision that would record an operational
value, a per-host private-value file, or an unencrypted secret.

Failure mode: a deploy that forgets `--override-input` evaluates the stub, and
that evaluation is indistinguishable from a clean clone's, so the stub assertion
cannot catch it — the assertion guards the defaults, not the forgotten override.
What refuses such a deploy is the deploy path's preflight in the per-host
rebuild alias.

Verification: `scripts/private_data_hygiene.py` runs over the recorded tree as
the flake check `private-data-hygiene` and is reused by the pre-commit hook and
CI; `@check:private-data-defaults` asserts the declared defaults are
placeholders or empty, and the stub assertion re-checks the same obligation in
the `verify.command` suite; and
`tests/integration/private-data-separation-test.nix` boots a machine whose
network values are supplied from outside the repository and asserts the booted
interface carries them. The deploy path additionally refuses to deploy when the
override supplied no values (a preflight in the per-host rebuild alias), because
a clean-clone evaluation and a forgotten override are the same stub evaluation
and the assertion cannot tell them apart.

## Typed option modules as the host/module contract

Reusable concerns are a pair of files: `options.nix` declares the typed surface
and `default.nix` renders the behaviour from it. Present pairs:
`modules/home-manager/{ssh,persistence}`, `modules/nixos/persistence`. Host
options of the same kind live beside the host (`networking.adlerkopf.*`,
`networking.cupix001.*`).

The contract exists so a shared module can be imported by hosts that do not
have the device-specific data, and so that a missing declaration is a
declaration error rather than a silently wrong default: `personalIdentityFile`
has **no default**, while `includedConfigs` and the persistence switches default
to disabled.

Notable current state: `networking.cupix001.*` declares thirteen options, none of
which is consumed by any module — the set is inert until `private.nix` and a
networking module exist.

## Impermanence and two-layer persistence

Stateful Linux hosts do not carry root state across reboots. thiniel wipes the
btrfs root subvolume on every boot; adlerkopf resets `@root` from a read-only
`@root-blank` snapshot. Everything that must survive is bound from `/persist` by
one of two layers:

| Layer | Option | Base paths | Examples |
|---|---|---|---|
| System | `mySystem.persistence` | `/etc/nixos`, `/var/log`, `/var/lib/nixos`, coredumps, `/etc/machine-id`, `/var/lib/sops-nix/key.txt` | service data, host identity |
| User (Home Manager) | `myHome.persistence` | `dev`, `Projects`, caches, `.config/sops/age`, opencode/omp state, `.bash_history` | working data, agent state |

Feature modules attach their own persistent paths to the user layer conditionally
(`lib.mkIf config.myHome.persistence.enable`), e.g. `.ssh`, `.mozilla`,
containers storage, KeePassXC, maestral. The Mac has no impermanence; absence of
that model there is not a claim of data loss.

Rationale: a root wipe is only safe if persistence is explicit and reviewable. A
path that nobody declares is intentionally lost, and the loss is visible in the
diff rather than discovered after a reboot.

## Secret material and key binding

Secrets live in per-host SOPS-encrypted YAML files. `.sops.yaml` maps each
`hosts/<host>/secrets.yaml` path to the age recipients allowed to decrypt it.
A host's age key is either a dedicated file (thiniel, macOS) or derived from the
host's SSH host key (`age.sshKeyPaths`), which removes an installation-time key
transfer for adlerkopf and cupix001.

Consumption is declarative: a feature reads `config.sops.placeholder."<key>"`
inside a `sops.templates` file, or the consuming unit reads the decrypted path
directly. Optional secrets gate optional behaviour:
`lib.optionalAttrs (config.sops.secrets ? "git/<identity>/name")` is what decides
whether a work-identity SSH entry or Git profile is rendered at all — so
"this host holds this identity" has exactly one representation.

Two facts worth noting: `.sops.yaml` currently assigns adlerkopf and cupix001
the **same** recipient value, and thiniel's key file is exposed to the user
session via `mkOutOfStoreSymlink`. Neither was audited on a live host.

## Dual-channel package strategy

The default package set is stable (`nixpkgs` → `nixos-26.05`). Two escape
hatches exist: `pkgs-unstable` (built by `lib/helpers.nix` from the
`nixpkgs-unstable` input and injected through `extraSpecialArgs`), used for a
small set of tools, and a separate `nixpkgs-darwin` input that the Darwin host
follows. `nixpkgs.follows` pins the shared addons (home-manager, stylix,
sops-nix, disko, lanzaboote, …) to the channel they belong to, so one flake
still evaluates as a coherent set.

Consequence: a host can end up mixing a stable system with unstable userland
packages by design; this is a declared choice, not drift.

A third source exists for exactly one tool: the coding agent takes its package
from the `nixpkgs-agent` input (`ompPackage` in `extraSpecialArgs`), because the
`nixpkgs-unstable` branch trails the agent's upstream releases by days. The
input is not a channel a host follows; it owns one package, and each device that
carries the agent asserts a version floor at evaluation time. Refreshing it is a
deliberate `nix flake update nixpkgs-agent`.

A fourth source is not a channel at all: OpenCode's 2.x line is distributed only
as prebuilt per-platform binaries and is not in nixpkgs (which carries 1.x), so
the repository packages it itself (`overlays/opencode`), pinning a version and a
checksum per platform. A refresh is a deliberate version-and-checksum edit, and
each device that carries it asserts the same floor. Failure mode: nothing in the
repository signals that a newer release exists, so currency depends on the
operator noticing (chapter 11 R-022).

## Platform conditionals

A single module serves both platforms where the difference is small, using
`lib.optionals`/`lib.optionalAttrs` on `pkgs.stdenv.hostPlatform.isDarwin` /
`isLinux` — module keybindings (`features/cli/kitty.nix`), `UseKeychain` and
`socat` behaviour (`features/cli/ssh.nix`), the Firefox package
(`features/productivity/browser.nix`), macOS daemon options
(`features/productivity/emacs-doom.nix`). Whole-platform concerns live in
separate directories (`features/macos`, `features/linux`) that only the matching
host imports. The Darwin host imports nothing from `hosts/common`.

## Error handling: assertions and fail-closed defaults

There is no application error handling here. Correctness is enforced at
evaluation time by `config.assertions` modules under `tests/assertions/`
(imported by the NixOS hosts and, individually, by the Darwin host and Mac
profile) and by the `checks` derivations. Two patterns recur:

- **Hard invariants as assertions** — firewall enabled, no empty/localhost
  hostname, no SSH root login, timezone/locale, disko target, `neededForBoot`
  paths, Secure Boot enabled on adlerkopf, `/var/lib/sbctl` persisted.
- **Fail-closed configuration** — a missing secret, key file, or declaration
  removes an entry rather than adding a fallback. SSH identity selection and the
  work-identity gates are the canonical examples.
- **Refusal at the tool boundary** — the coding agent's pre-execution guard
  refuses decryption commands and reads of decrypted material in the paths it
  declares protected (`/run/secrets/*`, a `sops/age/` path, `/var/lib/sops-nix/*`)
  in every approval mode (`.omp/hooks/pre/secret-access-guard.js`, installed by
  `features/development/omp.nix`); the `unit-agent-secret-guard` check drives the
  guard's verdict table, and QS-004 records the rule. The guard's coverage is a
  glob set, not every decrypted path on a device — `chapter 11` R-021 records the
  user-side sops-nix directory that falls outside it.

## Testability and the specification workflow

Verification is by native Nix targets, not by a step runner. Every scenario in a
change delta carries exactly one binding tag (`@check:<name>`, `@host:<name>`,
`@deploy:<name>`); `@e2e` scenarios must bind to a VM boot or a host
confirmed on hardware. Mechanical traceability is `scripts/givn-spec-trace.py`;
the human policy is `docs/GIVN-VERIFICATION.md`; the graph and hooks are
`givn/config.yaml` and `givn/commands.yaml`.

The three present layers are unit (`lib.debug.runTests` → `unit-helpers`),
evaluation-time assertions (host `config.assertions`), and QEMU integration
(`pkgs.testers.runNixOSTest`). A fourth kind of check exists for an artifact with
its own interface rather than an option: `unit-agent-secret-guard` runs the
agent's guard hook under bun and asserts its verdicts, which is the only way to
prove a tool-boundary refusal without a model-backed session. The documented
`tests/deploy/` layer does not exist, so `@deploy:` bindings are unresolvable
today.

## Theming and desktop configuration

`stylix` supplies a single system-wide palette (One Light) with
`autoEnable = false`; each target is opted in per module (`stylix.targets.<x>.enable`).
The palette is inlined in the host modules to avoid import-from-derivation, so
cross-system evaluation from macOS works without building. Linux desktop
concerns (Hyprland, waybar, mako, fuzzel, gtk/qt, fonts) are separate feature
modules imported only by thiniel.
