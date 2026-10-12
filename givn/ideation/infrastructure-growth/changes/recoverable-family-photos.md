# Change seed: recoverable-family-photos

Status: ready

- Use-case IDs: make-application-available, access-shared-information, preserve-recoverable-application-state, recover-hosted-applications
- Topic: infrastructure-growth
- Personas: owner--operator, family--application-user
- Suggested start: 2 if consuming recover-hosted-state; otherwise independently deliverable with its own complete photo recovery. Other-app/generic recovery proof does not prove the photo procedure. No dependency on usable-personal-work or bounded-application-reachability merely from naming order.
- Handoff: confirmed 2026-10-11 through the accepted mapping/four-guarantee cut (Q18) and both approved persona promotions (Q19/Q20); ideation only, not proposed/implemented and no active change started.

## Deliverable guarantee

A qualified hosted photo application is usable by intended family users and selected outside recipients through its own ordinary-internet sharing flow, without general family/private-network access. Required persistent/coherent state has a usable independently surviving recovery point meeting the photo-only 24-hour condition, with supported restoration and verified native content/access before intended paths reopen. Common access/recovery arrangements are reused where applicable, not custom album/sharing/authorization software.

Complete app operation, access, state and actual recovery evidence must ship together; no public process with unhonored backup flags is ready. This seed does not claim the separate existing-application path-change goal merely because initial/restored routes exist.

## Accepted decisions

### Complete standalone guarantees instead of partial setup

- Context: the adopted six actor-goal contracts require complete application/data/recovery/work outcomes. Initial setup or restoration of a route does not cover a deliberate existing-application path change. The user adopted the four-deliverable Handoff cut (Q18).
- Options:
  1. **Adopt the six-leaf/four-guarantee cut** — each goal keeps its own permanent leaf and each seed delivers an end-to-end result with true/conditional dependencies.
     In practice: a photo app without a usable required recovery point and an editor without required working state are unfinished; a passive path flag is not a completed reachability change.
     Gain: independently shippable results without silent uncovered goals or config-only completion.
     Cost: each real target, procedure, source and meaningful proof must be supplied; this is not a universal platform shipped by one settings change.
  2. **Revise a named delivery boundary first** — regroup a complete guarantee while preserving the accepted rules.
     In practice: photo hosting may be the first real recovery target in a merged guarantee, rather than forcing a generic empty backup fixture first.
     Gain: better fit for the desired first actual target.
     Cost: revisit affected coverage/dependencies before implementation; no intermediate state may violate readiness/protection.
- Chosen: **Adopt the six-leaf/four-guarantee cut** because the user explicitly said "Adopt this cut". Rejected: revising a named boundary first because the displayed cut was accepted. This is an approved seed boundary, not product/source selection, deployment, release-order commitment or automatic change start.

### Selected outside viewers, not family-only or unrestricted public publication

- Context: the family photo example must permit outside recipients through the hosted application's own sharing feature (Q12); this repository enables hosting/network compatibility rather than building sharing logic.
- Options:
  1. **Selected outside viewers too** — the app can grant access to an album without broad family-application access.
     In practice: a friend views a shared holiday album without joining the family's application audience generally.
     Gain: useful scoped sharing without broad access.
     Cost: the real app must supply the required supported guest flow; recipients may retain copies after access withdrawal.
  2. **Family-application users only** — outside viewers first become general family-application users.
     In practice: a friend cannot view an album without entering that broader audience.
     Gain: one audience boundary.
     Cost: does not satisfy the selected guest-sharing requirement.
  3. **Public sharing as a required goal** — explicitly published albums need no individual permission.
     In practice: anyone receiving the published address can view its content.
     Gain: broad low-friction publication.
     Cost: distribution can exceed intended recipients; withdrawal does not recover retained copies.
- Chosen: **Selected outside viewers too** because the user chose option 2 of the original audience question and assigned its implementation to the hosted app. Rejected: family-only because invited outsiders are required; public publication as a required goal because selected recipients were chosen. No additional download/edit/reshare rights or custom grant engine is inferred.

### Ordinary internet access while the app controls photo rights

- Context: network reachability for invited recipients changes enrollment and exposure (Q13).
- Options:
  1. **Ordinary internet access** — required guest-facing endpoints are reachable without private-network enrollment or general family access; native app authorization still applies.
     In practice: a friend opens the app-generated shared-album flow from a phone's ordinary connection.
     Gain: no per-guest network setup and a compatible native sharing flow.
     Cost: maintain the necessary internet-facing surface and compatible edge protection; endpoint reachability is not public album content.
  2. **Private-network access first** — the app can be reached only after an approved private connection is established.
     In practice: the friend must set up that connection before using the album invitation.
     Gain: no generally internet-reachable guest surface.
     Cost: per-viewer provisioning/support and does not meet the chosen ordinary-internet requirement.
- Chosen: **Ordinary internet access** because the user explicitly selected it. Rejected: private-network enrollment first. No blanket edge-auth bypass or administrative exposure is authorized.

### Photo recovery point, not zero loss or fast failover

- Context: the user delegated a sensible recent-photo-loss choice and had already given recovery speed low priority (Q3).
- Options:
  1. **24-hour maximum recovery-point age** — a usable coherent point must be within 24 hours of assessment/failure; recovery is manual without a strict completion deadline.
     In practice: an 18:00 failure can recover a same-day 02:00 point, with later uploads/edits potentially absent.
     Gain: daily-backup-oriented family-lab baseline.
     Cost: recent sole-copy photos may be permanently lost; a schedule/green job does not prove a fresh usable independent point.
  2. **One-hour maximum age** — a tighter recent-state window.
     In practice: an 18:00 failure needs a 17:00-or-later point.
     Gain: less recent work can be absent.
     Cost: more frequent supported capture/durability work without a demonstrated family need yet.
  3. **No acknowledged writes lost** — every accepted photo/change survives loss of original server/storage.
     In practice: an upload accepted just before failure still survives.
     Gain: no recent-write loss within that failure scope.
     Cost: supported durability beyond the failed server at acknowledgement, not ordinary periodic backups; no selected app's support is known.
- Chosen: **24-hour maximum age as an assistant planning assumption under explicit user delegation**, not a numerical preference supplied by every stakeholder or an implemented guarantee. Rejected: one hour for lack of a demonstrated stronger need; zero acknowledged loss because it requires stronger supported durability than the chosen baseline. Measure captured state time against assessment/failure, not job finish or delayed restore completion. No other app/personal target is inherited.

## Open questions

### Qualified photo application and native capture/restore procedure (Q17)

Which real photo application and supported capture/restore will supply native selected-recipient sharing, compatible intended endpoints, coherent originals/metadata/needed credentials and usable restoration? This blocks product-specific implementation/proof. Choose during the normal proposal/design; no package/version or URI/token convention is guessed. Unsupported behavior cannot be replaced with custom sharing or a dummy backup.

### Actual hosting, copy and bootstrap bindings

Which approved hosts/state paths/copy source and surviving bootstrap inputs implement the selected product's complete guarantee? The topic did not test provider access or current recovery. Bind real inputs and verify native permitted/denied use after original-loss restoration; old sharing metadata may require owner review through supported app controls before public access returns, not automatic reconstruction of lost changes.
