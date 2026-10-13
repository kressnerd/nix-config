# Proposal: github-fetch-credential

## Release note

The laptop thiniel and the work MacBook fetch the private GitHub sources of
this configuration with a credential each machine declares, so nix pulls
without a hand-exported token and without a token file every local account can
read.

## Use-Case Context

- Use-case ID: `reproduce-working-environment`
- Ideation topic: infrastructure-growth
- Seed path: none — this change covers one condition (a device's own access to
  the private source of its configuration, supplied by the credential the
  device declares) of the ready seed `usable-personal-work`, whose deliverable
  guarantee spans the whole usable personal environment and stays open. No seed
  status line is stamped, because this change does not deliver that seed's
  end-to-end guarantee.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the affected
  surface is the owner's own devices and the credential they present, and the
  owner is the only actor who judges whether a build or update on a device
  resolves the private source. `family--application-user` is not affected: no
  hosted application, shared resource, or access path changes here.

## Problem / Opportunity

The configuration depends on a private source that nix must download, and the
credential that makes that download work is neither declared by any device nor
safely held.

Observable today:

- One input of the flake is the private repository `kressnerd/givn`; an
  anonymous request for it answers "not found" from both the API and the
  archive endpoint. Any evaluation that must actually download it — a fresh
  checkout, a refreshed lock, a build on a machine whose store no longer holds
  that revision — cannot resolve the input. The revision already present in the
  store is what hides this, and the owner's shell history shows the credential
  being prepared immediately before the input was last refreshed.
- The credential is a plaintext file in the owner's home
  (`~/.secret/github-token`, mode 0644, a fine-grained GitHub token created
  2026-10-12). Every local account on the machine can read it.
- It reaches nix only through a hand-performed step: each shell session appends
  the file's contents to one of nix's settings inside an environment variable.
  A session that skipped that step, a command running as root
  (`sudo nixos-rebuild`), and the coding agents' own sessions all fetch
  unauthenticated.
- The file is declared by no device, sits outside the paths that survive the
  laptop's root wipe, and is the only copy — a wiped or fresh device has no
  credential at all, and nothing in the configuration reports that.

Operator impact: the private source of the configuration is fetched by luck of
what the store happens to hold and by a step repeated in every session, while
the credential itself is readable by every account on the machine and is not
reproduced on a rebuilt device.

## Proposed Solution

The credential becomes device state that the configuration declares and
supplies, observable as follows:

- The two machines that develop and build this configuration — the laptop
  thiniel (NixOS) and the work MacBook (nix-darwin) — each declare their GitHub
  fetch credential as secret material in that machine's own secret file. The
  value is supplied by the operator when the file is encrypted and is recorded
  only encrypted; the repository gains one encrypted entry per machine and no
  plaintext credential.
- On the device the credential is materialized as a file readable by root and by
  the owner's account alone — no other local account can read it — and it is
  never placed in a world-readable store path and never in a process environment
  variable. The file belongs to the owner's own account with mode 0400 and root
  reads it by privilege: no group on either machine contains only the owner (the
  Linux build machine's second account shares both candidate groups, and on
  macOS every standard account shares the owner's primary group), so a
  root-owned file readable by the owner alone cannot be expressed on both.
- The device's nix configuration refers to that file, so every nix process on
  the device — the owner's shells, the owner's coding agents, and root's build
  and switch commands — presents the credential when it fetches from the GitHub
  host, with nothing prepared by the operator beforehand.
- A device that declares no such credential has no credential file, and its
  fetches stay unauthenticated: no device borrows another device's credential,
  and none picks up one that a session happened to export.
- The credential is part of the device state that survives the laptop's root
  wipe, so a rebooted or rebuilt laptop resolves the private source again
  without the operator re-creating the file by hand.
- The existing rule that a revision recording an unencrypted secret is refused
  keeps holding, and a clean checkout that holds no credential still declares
  none.

No other host declares the credential: the home server, the edge server and the
test virtual machines are not development or build machines, and each declares
no credential file and carries none in its nix configuration.

Rejected while choosing the shape: keeping the credential as a plaintext file
outside the repository that the configuration merely points at (today's file).
A path reference does not recreate a credential on a wiped or fresh device, and
this repository already records credentials of this class as encrypted
per-device secret entries — the documentation-lookup key and the web-search key
are exactly that.

## Capability Routing

`givn spec route --change github-fetch-credential` reported **EXTEND
quiet-configuration-evaluation** (score 13.00, confidence: signal). The route
matched the untouched template's placeholder text and generic words, not the
subject: quiet-configuration-evaluation owns a release's superseded defaults and
what an evaluation prints to triage, under the publication contract. Nothing
here changes how an evaluation reports, so its recommendation is declined.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| github-fetch-credential | EXTEND quiet-configuration-evaluation (score 13.00, signal) | NEW in reproduce-working-environment | The observable subject is a device's own access to the private source of its configuration through the credential that device declares — the device-owner contract states exactly this: needed source access established without broadening rights or exposing raw secret material. No publication behaviour changes: the repository records one more encrypted secret entry and no repository-facing rule changes. |

## Out of Scope

- The hosts that do not develop or build this configuration — the home server,
  the edge server, and the test virtual machines. The owner restricted the
  credential to the development and build machines (the laptop thiniel and the
  work MacBook) on 2026-10-14; a deploy that evaluates on any other host
  fetches unauthenticated, exactly as it does today.
- Making the repository's own automated evaluation run again. The `secret-scan`
  workflow fails on every push — eight of the last eight runs, at the step that
  evaluates the repository — because a GitHub runner holds no credential for the
  private source. Repairing that needs a credential inside GitHub's own
  settings, which this configuration cannot declare. Recorded as D2; not
  repaired here.
- The private source itself: it stays private, is not vendored, and is not
  replaced.
- Creating, narrowing, or rotating the token at the provider, and revoking the
  exposure of the existing plaintext file: operator actions at GitHub, not
  device configuration.
- Every other credential, and the wider inventory of approved sources for the
  owner's personal state and identities, which stays open as Q16 of the
  ideation topic.
- The publication contract's existing guarantees and every host's network
  values.

## Open Questions

### D1 — How far the credential reaches

- Question: must the credential serve only the owner's own account, or every
  nix process on the device including root's build and switch commands, or also
  the repository's GitHub runner?
- Options:
  1. **The owner's account only** — the credential is readable by the owner's
     account and no other, and only nix commands that account runs present it;
     gain: the narrowest custody, nothing running as root can read it; cost: a
     build or switch whose store no longer holds the revision still fetches
     unauthenticated, which is the failure this change exists to remove; in
     practice: the owner's own lock refresh works with nothing prepared, while
     `sudo nixos-rebuild switch` on a machine whose store was collected still
     cannot download the input.
  2. **The whole device** — the credential is readable by root and by the
     owner's account and by no other local account, and every nix process on
     the device presents it; gain: no fetch path depends on what the store
     happens to hold; cost: the credential is readable by root and by anything
     running with root's privileges; in practice: after a store collection, a
     switch or build by root still resolves the private input.
  3. **The whole device plus the repository's GitHub runner** — as option 2,
     and the same credential is also registered where GitHub's runner can read
     it so the repository's own evaluation runs again; gain: the only automated
     run of the hygiene guard goes green; cost: the credential exists in a
     second custodian with no declarative representation, and rotating it means
     editing GitHub's settings as well.
- Disposition: answered 2026-10-14 (user) — **the whole device (option 2)**:
  every nix process on the machine, the owner's account and root alike. The
  owner restricted the credential to the machines that develop and build this
  configuration — the laptop thiniel (NixOS) and the work MacBook (nix-darwin) —
  on the same day, so no other host declares it.
  Rejected: option 1, because it leaves root's build and switch path dependent
  on the store happening to hold the revision, which is the defect being
  removed; option 3, because it would put the credential in a second custodian
  outside this configuration, and the runner's failure is carried as D2
  instead.

### D2 — The repository's evaluation that cannot fetch its own input

- Question: the repository's automated evaluation currently fails because it
  cannot fetch a private input — should it stay as it is, gain a credential that
  GitHub's runner can use, or lose the dependency on the private source?
- Options:
  1. **Leave it failing** — gain: nothing further to custody, and the failure is
     documented; cost: the only automated run of the repository's hygiene rule
     does not run, and a push can reintroduce a recorded operational value or
     unencrypted secret unflagged; in practice: a revision that records a real
     address is caught by the operator's own machine, not by the repository.
  2. **Register the credential where the runner can read it** — gain: the
     repository's evaluation and hygiene rule run on every push; cost: the
     credential exists in a second custodian with no declarative representation,
     and a rotation must be applied in GitHub's settings too; in practice: the
     push evaluates the repository with the private input downloaded.
  3. **Remove the dependency on the private source** — gain: no credential is
     needed anywhere, including the runner; cost: it publishes a repository the
     owner keeps private, or adds a vendored copy to maintain; in practice: a
     clean checkout of the repository evaluates with no credential at all.
- Disposition: out of scope — the user selected whole-device reach and excluded
  the runner when answering D1 (2026-10-14). The failure and its evidence are
  recorded here so the gap is not lost. Owner: the operator; a later change or a
  GitHub settings action decides it, since this configuration cannot declare a
  runner-side credential.

### D3 — One credential or one per machine

- Question: is the credential the existing fine-grained token, copied encrypted
  into each build machine's secret file, or a new token, shared by these
  machines or issued per machine?
- Options:
  1. **Reuse the existing token on both machines** — gain: nothing new to
     create or hand over; cost: its rotation is coupled to whatever else uses
     it, and both machines hold the same secret, so revoking one revokes both;
     in practice: the token that today sits in the owner's home is encrypted
     into the laptop's and the MacBook's secret files.
  2. **Issue one new token for these machines** — gain: its rotation is
     independent of the owner's other uses of GitHub; cost: one more item to
     create and to rotate, and each machine's readable copy still carries the
     same grant; in practice: a new fine-grained token limited to reading the
     private source, encrypted into the laptop's and the MacBook's secret files.
  3. **Issue one token per machine** — gain: one machine's copy can be revoked
     or rotated without touching the other; cost: one token per build machine to
     create and to keep track of, and one more item wherever they are recorded;
     in practice: the laptop's copy is revoked without affecting the MacBook.
- Disposition: carried — owner: the operator; the design artifact settles the
  secret's name, which machine's secret file carries it, and how each machine
  turns the declared value into what nix reads, and the operator supplies or
  creates the value when the secret is encrypted.
