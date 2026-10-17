# Frame: secure token keys

Status: confirmed 2026-10-17 (user) — Q1–Q7 settled the goal, staged scope, first-stage boundary, token roles, threat model, and the recovery/guarantee conflict. The Frame is adopted for discussion/modeling only; it does not authorize implementation.

## User-supplied context

On 2026-10-17 the owner stated: "I want to use secure token key hardware." The owner holds a Swissbit iShield Key and a Solo 2. The supplied research describes generic FIDO2/CTAP2.1 support on NixOS — `libfido2` udev rules, PAM U2F, `ed25519-sk` SSH keys, browser WebAuthn — and Solo 2-specific udev/firmware handling. The owner did not state which outcome the tokens must protect, which devices must use them, or against which threat; Q1–Q7 settled those choices.

## Confirmed decisions

| Question | Decision |
|---|---|
| Q1 — outcome | **All, staged.** Device privilege authentication, remote identity, web-account authentication, and secret/disk unlock are all in scope, delivered one surface at a time. "All" does not promise FIDO2 disk unlock on `thiniel` (OPAL SED) or a compatible age plugin. |
| Q2 — first stage | **Remote identity.** A token-held SSH identity authenticates the owner's private-repository and server connections. |
| Q3 — first-stage scope | **Personal identity on `thiniel` only.** The work Mac and all work identities stay file-based in this stage. Server access that already trusts the `thiniel` personal identity is included. |
| Q4 — token roles | **Swissbit daily, Solo 2 backup.** The Swissbit is carried daily; the Solo 2 is stored separately and registered as a separate credential on the same remotes. |
| Q5 — threat model | **All of the above, staged.** Overall: stolen device/copied data, malicious local process/unattended session, and remote account/credential compromise. The first stage does **not** claim any of these as delivered (revised by Q7). |
| Q6 — recovery | **Keep the file key on `thiniel` as a fallback.** `~/.ssh/id_ed25519` stays authorized and on disk. |
| Q7 — conflict resolution | **Keep the file key; defer the stolen-device guarantee.** The first stage delivers token enrollment and token-preferred daily use with the file key as fallback. The stolen-device/copied-data guarantee moves to a later stage that removes the file key after a recovery mechanism exists. |

## Research protocol

Commands run:

- `givn instructions`, `givn instructions dialog`, `givn instructions ideation`, `givn instructions domain-modeling`.
- `givn status`: no active change; nine archived changes.
- `givn spec tree`: two permanent use cases — `publish-infrastructure-configuration` and `reproduce-working-environment` — with seven capabilities.
- `find`/`grep` across `hosts`, `modules`, `home` for FIDO2, U2F, WebAuthn, PAM, Solo 2, YubiKey, `ed25519-sk`, `systemd-cryptenroll`, LUKS, and TPM.

Documents read:

- `README.md` (repository structure, security, deployment).
- `docs/arc42/03-context-and-scope.md` (business/technical context).
- `docs/arc42/12-glossary.md` (identity, SOPS, secret, host, device-owner terms).
- `givn/specs/reproduce-working-environment/usecase.md` and `permitted-identity-selection.feature`.
- `home/dan/features/cli/ssh.nix`, `sops.nix`, `sops-age-key.nix`.
- `modules/home-manager/ssh/options.nix`.
- `hosts/common/users/dan.nix`.
- `hosts/thiniel/default.nix` (login, PAM, disk encryption, SSH, SOPS).
- `hosts/adlerkopf/default.nix`, `tpm2.nix`, `secure-boot.nix` (server auth and LUKS/TPM).
- `hosts/J6G6Y9JK7L/default.nix` (work macOS host).
- `home/dan/features/linux/gnome-keyring.nix`, `keepassxc.nix`, browser preferences.
- `givn/ideation/infrastructure-growth/` (session, frame, use-case definitions, domain terms, elaborated `reproduce-working-environment`).
- `givn/personas/owner--operator.md`, `givn/personas/family--application-user.md`.

## Source findings

| Surface | Current state | Evidence strength |
|---|---|---|
| FIDO2 token support | No `libfido2`, `pam_u2f`, `solo2-cli`, or FIDO2 udev declaration in any host, module, or home feature. | Source absence. |
| SSH identity | File-based ed25519 keys. `myHome.ssh.personalIdentityFile` names the file; `permitted-identity-selection` proves the configured resolution on `thiniel` and `J6G6Y9JK7L`, including a booted VM. | Declared and VM-verified for file identities. |
| SOPS / age | `thiniel` uses `/persist/system/var/lib/sops-nix/key.txt`; `adlerkopf` derives age from the persistent SSH host key; `age-plugin-yubikey` is installed on `thiniel` but no PIV token is declared. | Declared; live decryption not audited. |
| Login / PAM | `thiniel` uses greetd/tuigreet password login, gnome-keyring PAM integration, and a Hyprlock PAM service. No U2F factor. `adlerkopf` disables password SSH and passwordless sudo and authorizes one file-based SSH key. | Declared. |
| Disk encryption | `thiniel` states OPAL SED full-disk encryption and disables sleep; `adlerkopf` uses LUKS2 with TPM2 unlock; `cupix001` uses LUKS2; `nixos-vm-minimal` uses LUKS2. | Declared; no unlock exercise recorded. |
| Browser / WebAuthn | Firefox preferences exist; no hardware-token enrollment is described. `J6G6Y9JK7L` disables macOS passkeys in the company profile. | Declared preferences, not token behavior. |
| Work macOS host | Separate nix-darwin host; PAM U2F is a Linux/PAM mechanism and does not apply as-is. ssh-agent uses launchd. | Declared. |
| Existing stakeholders | Only the owner/operator uses these devices and identities; family application users have no infrastructure-administration role. | Confirmed persona records. |

## Problem

The owner holds two FIDO2 security keys but no declared device behavior uses them. The same hardware supports several unrelated guarantees — local privilege, remote identity, web accounts, and secret/disk unlock — with materially different lockout and recovery costs. The owner wants all four surfaces, staged, beginning with remote identity on `thiniel`.

## Vision

The Swissbit iShield Key and Solo 2 back the owner's authentication across the owner's devices and identities. Each surface is delivered as a standalone stage with a tested recovery path, instead of one broad change that leaves several unproven auth paths active at once. The first stage makes the personal identity on `thiniel` usable through the token: the owner authenticates to personal private repositories and the servers that trust that identity with the daily Swissbit, keeps the Solo 2 as the separately stored backup, and retains the file key as a fallback. It proves that the token path works; it does not yet claim theft resistance.

## First-stage boundary

| Dimension | Decision |
|---|---|
| Client device | `thiniel` only. |
| Identity | The personal identity used for private repositories and the servers that already trust it. |
| Daily token | Swissbit iShield Key. |
| Backup token | Solo 2, stored separately, registered as a separate credential. |
| Existing file key | `~/.ssh/id_ed25519` stays authorized and on disk as the fallback. |
| Threat claim | The stage proves token enrollment, token-preferred daily use, and the backup credential. It does **not** claim that a stolen device or copied home directory yields no usable identity. |
| Out of scope | The work Mac (`J6G6Y9JK7L`), work identities, PAM/login, WebAuthn, SOPS age, and disk unlock. |

## Staged scope (Q1)

All four surfaces are in scope. They are independent guarantees and are not merged into one use case or one change seed.

| Surface | Owner outcome | Platform limit | Stage status |
|---|---|---|---|
| Remote identity | A private-repository or server connection authenticates with a token-held identity. | Requires a compatible OpenSSH/agent on each client, including the work Mac. | **First stage:** personal identity on `thiniel` with file-key fallback. |
| Device privilege authentication | Local login or privileged command succeeds with the declared token factor. | Linux PAM only; macOS login/sudo is not covered. | Later. |
| Web-account authentication | Browser-account enrollment uses the token as a WebAuthn authenticator. | Account-side enrollment; repository supplies device recognition only. | Later. |
| Secret/disk unlock | SOPS age material or a LUKS volume is unlocked with the token. | LUKS hosts only; `thiniel` uses OPAL SED and is excluded from FIDO2 disk unlock. Age requires a compatible plugin and a recovery key. | Later. |

The stolen-device/copied-data guarantee, per-use verification for the malicious-local-process threat, and WebAuthn for remote-account compromise are later stages. Every stage must leave the owner able to recover when a token is lost, forgotten, or broken.

## Stakeholder inventory

| Party | Evidence | Interests | Confirmation |
|---|---|---|---|
| Owner/operator | Holds both tokens and requests their use. | Stronger and more portable authentication for their own devices and identities; no lockout; a working fallback. | Confirmed as a stakeholder by the existing `owner--operator` persona; the token-specific interests are recorded in Q1–Q7. |
| Family application users | Confirmed stakeholder for hosted applications. | Unaffected unless a later token stage changes application access. | No token-related interest established; do not invent one. |
| Devices | `thiniel` is the first-stage client; `J6G6Y9JK7L`, `adlerkopf`, `cupix001`, and `nixos-vm-minimal` are later or remote surfaces. | Must accept the chosen token surface on the platform where it is declared. | `thiniel` selected by Q3; other devices are not in the first stage. |

No new persona is proposed at Frame time. The existing `owner--operator` persona covers the owner; no token-specific authority or capability is inferred beyond the confirmed decisions.

## Scope

In scope for discussion: using the Swissbit iShield Key and Solo 2 for the four staged surfaces; primary/backup handling; recovery when a token is lost or unavailable; native verification.

Not authorized: configuration edits, deployment, givn change creation, permanent specs, persona or term promotion, or handling of secret material.

## Constraints and known facts

- FIDO2 is a standard protocol; both stated devices are FIDO2/CTAP2.1-capable per the supplied research. The Swissbit's exact model and its PIV/TOTP/HMAC-secret support are unconfirmed and are not needed for the SSH first stage.
- `libfido2` supplies generic udev rules; Solo 2 additionally needs `solo2-cli` for firmware and its non-FIDO2 USB modes. Normal FIDO2 use may work with `libfido2` alone; the design must verify which udev rules the Solo 2 needs.
- PAM U2F applies to Linux PAM services only. macOS login/sudo is not covered by `pam_u2f`.
- `ed25519-sk` keys are device-bound; the on-disk artifact is a key handle, not the private key. Backup requires a second registered credential unless the token supports exporting/duplicating (it does not).
- SOPS age currently depends on file or SSH-host-key material. Token-backed age requires a compatible plugin and a recovery path; `age-plugin-yubikey` is PIV-only and no PIV token is declared.
- `thiniel` uses OPAL SED encryption, not LUKS; `systemd-cryptenroll` FIDO2 unlock applies only to LUKS devices.
- A required PAM factor on login is a lockout risk if the backup token is not registered first.
- The first stage keeps the file key, so its success guarantee must not be described as theft-resistant. Removing the file key requires a later recovery decision.

## Open inputs

- Swissbit model and FIDO2/PIV/TOTP/HMAC-secret capability inventory — not Frame-blocking for the SSH first stage; needed before later stages and for resident-key capacity.
- The later recovery mechanism that permits removing the file key and delivering the stolen-device guarantee.
- Per-use verification (PIN/`verify-required`) and WebAuthn stage scoping.
- The exact udev/Solo 2 package needs, and whether the first stage uses resident keys or key-handle files.
- The work Mac's OpenSSH/agent compatibility for a later remote-identity stage.

## Gaps and next action

The Frame is ready for confirmation. After confirmation, proceed to Event Storming for the first stage and record terms; no event storming, use case, persona, term, or change seed exists yet.
