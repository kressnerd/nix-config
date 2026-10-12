# Growing personal and family infrastructure

Status: ideation handoff complete. The user confirmed the Frame, review personas, six-goal permanent mapping, four standalone deliverable guarantees and both persona promotions. This record starts no change and describes requirements/planning decisions, not deployed behavior.

## Purpose

Operate a self-hosted family datacenter so family members can use applications without being required to use cloud applications, while keeping the owner's laptops/workstations reproducible as usable everyday working environments. The home lab is still growing; the solution must accommodate later applications rather than hard-code a photo-only platform.

The first family example is sharing a photo album. Accessing shared documents and managing a household calendar are also confirmed valid tasks, with more applications expected. Photo sharing selects the first concrete narrative, not the only scope or a binding release order.

The original problems are repeated access setup for each new application and losing application data when a server fails. Backups/recovery belong in server/infrastructure setup. Personal-device reproduction must restore a usable work context, not only install familiar tools.

## People and authority

- **Owner/operator:** configures family infrastructure and personal devices, evaluates actual operation/access and recoverability, and may help family members use applications. This does not imply unrestricted rights over family members' or third parties' data.
- **Application users:** family members and selected invited recipients use the functions/resources granted to them. They do not operate shared infrastructure merely because they use an app or need help.
- **Device owner** and **Backup agent for the Owner/operator** are actor roles in particular flows, not extra personas.

The user approved project-level promotion of the [owner/operator persona](../../givn/personas/owner--operator.md) and [general application-user persona](../../givn/personas/family--application-user.md). The latter retains its stable ID after generalization; there are no album-viewer, internet-user or VPN-user persona segments. Dated topic stances remain separate from the stable cores. Complete [topic-local persona histories](../../givn/ideation/infrastructure-growth/personas/) are retained; proposed/applied promotion diffs are recorded with their respective decisions.

Manual family application-use help is part of the operating context. No help-desk application, response-time promise, automated solution or outsider support obligation is inferred.

## Infrastructure owns delivery, not application features

The selected photo application supplies album sharing and guest authorization. The same boundary applies to document editing and calendar functions: choose qualified hosted applications and configure compatible infrastructure; do not build those application features in this repository.

For photos, selected outside recipients must reach the app's native guest flow over an ordinary internet connection. They need neither private-network enrollment nor general family-application access. Native app rights still decide which resources they may use; a reachable endpoint does not make all photos public.

Reachability is **per application**. Some applications are internet-accessible; others are inside the family VPN only. This is a configuration/access policy, not a different persona. Initial setup, restoration and a deliberate later path change must all respect that policy without accidental broader access, blanket edge-authentication bypass or administrative exposure.

VPN software/configuration may be needed on a device for a selected application. It is not the defining outcome or a mandatory gate for every base laptop/workstation setup. No VPN product, new topology, native invitation format or application-specific route is selected by ideation.

## Recovery baseline and its limits

The user gave family-infrastructure recovery speed low priority and delegated a sensible photo-data-loss choice. The assistant selected a **24-hour photo recovery-point target** as a planning baseline, with manual recovery and no strict completion deadline.

A point is usable only when its coherent application state and required bootstrap can survive loss of the original server/storage and support restoration. Application state includes the nonreconstructible data its supported procedure requires, not merely original photo files. A same-server persistence area, snapshot, source-path reference or green copy-job result does not alone prove that condition.

Use the time the state was captured, not the job's finish time. For example, a point captured at 02:00 before an 18:00 failure is sixteen hours old relative to that failure. Completing its restore two days later does not change that data-loss window. A job that finished recently but captured state twenty-six hours before failure misses the photo target.

**This is not zero data loss.** Uploads, edits or metadata newer than the recovered point may be absent; sole-copy recent photos can be lost permanently. An older usable fallback can still be useful but must not be silently relabeled as meeting an unmet target or containing later lost work. Restored sharing/access metadata can also predate changes; the owner checks current intended access through the app's supported controls before reopening intended paths. No automatic reconstruction of lost grant changes is invented.

The photo target is not a universal requirement for other applications or personal working data. No backup product, destination, retention period, retry scheme, automatic failover, monitoring platform or personal-data loss window is chosen here.

## Usual working environment means work readiness

The personal-device goal is to reproduce the owner's usual usable working environment on the selected laptop/workstation. Success includes:

- Intended tools/settings for that device and its intentional platform differences.
- Actual required working files and mutable application state at the approved state/version or point.
- Permitted usable identities retrieved or re-established through approved supported procedures.

A configured editor, directory creation, successful evaluation or green transfer is not enough if required work or access is missing. Source/bootstrap preparation belongs inside this outcome. It may retain correctly available state, retrieve authoritative state, restore a suitable copy, or re-establish a platform-bound identity where supported; it is not blanket home-directory or credential cloning.

Approved definition/bootstrap material must be available without assuming the completed target environment already exists. A credential path or encrypted declaration cannot regenerate lost private material. Missing, unreadable, unauthorized, wrong-version or unsupported state must produce a truthful not-ready outcome and preserve already available required working data rather than downgrade the goal to software/settings only.

## What research establishes—and does not

The [Frame's source inventory](../../givn/ideation/infrastructure-growth/frame.md#personal-state-source-inventory--source-evidence-not-runtime-proof) separates reconstructible configuration, mutable work/app state, identity/bootstrap, local retention, sync and backup evidence.

Tracked Linux profiles declare impermanence retention for workspaces and several app/credential paths. macOS uses ordinary persistent home storage rather than the same root-reset model; absence of impermanence there is not a claim of data loss on reboot. Profiles compose device-specific features and supported overrides.

The inspected declarations show sync clients and credential references, not tested availability of every required external source or independent key escrow. The inspected client host also explicitly defers automated versioned backups. Private inputs, actual key/data payloads, external provider sessions and out-of-repo backup arrangements were not audited. Sync can supply useful state and providers may offer their own history, but configured sync alone is not an application-consistent recovery proof.

The [event narrative](../../givn/ideation/infrastructure-growth/eventstorming.md) records command/event/policy/read-model partners for application setup/access, copies and assessment, failure/replacement/restoration checks, manual help, complete personal work, approved identity bootstrap and state availability. Configuration records, hosted systems and human interactions are named as those kinds, not invented aggregates. No repository-owned aggregate is declared by the empty durable glossary; none was minted to fit notation.

All eight current Mermaid canvases have rendering coverage. The changed personal-readiness and two preparation diagrams were rendered in isolated Firefox and visually inspected; earlier canvases retain their recorded proof. No app was deployed, no real copy/restore/identity bootstrap or personal data transfer happened, and no actual device was reproduced.

## Six bounded actor-goal contracts

Sizing and elaboration passed fresh-context reviews. Each `!` goal maps to its own future permanent leaf through the normal proposal/spec flow, not a capability hidden under an umbrella server/component goal. Required state/bootstrap/recovery subfunctions do not turn a single complete readiness outcome into a config-only intermediate deliverable.

| Goal and contract | Primary actor | Boundary / future permanent leaf |
|---|---|---|
| [Make an application available](../../givn/ideation/infrastructure-growth/use-cases/make-application-available.md) | Owner/operator | Complete agreed hosting readiness; `givn/specs/make-application-available/usecase.md`. |
| [Change an application's paths](../../givn/ideation/infrastructure-growth/use-cases/adjust-application-reachability.md) | Owner/operator | Deliberate bounded change on an existing app, not just setup/recovery; `givn/specs/adjust-application-reachability/usecase.md`. |
| [Preserve recoverable application state](../../givn/ideation/infrastructure-growth/use-cases/preserve-recoverable-application-state.md) | Owner/operator; supporting delegated backup agent | Usable surviving point meeting declared protection, not a schedule flag; `givn/specs/preserve-recoverable-application-state/usecase.md`. |
| [Restore hosted applications](../../givn/ideation/infrastructure-growth/use-cases/recover-hosted-applications.md) | Owner/operator | Verified recovered data/use and intended current access; `givn/specs/recover-hosted-applications/usecase.md`. |
| [Reproduce usable usual work](../../givn/ideation/infrastructure-growth/use-cases/reproduce-working-environment.md) | Device owner | Full work context including required state and permitted identities; `givn/specs/reproduce-working-environment/usecase.md`. |
| [Access shared information](../../givn/ideation/infrastructure-growth/use-cases/access-shared-information.md) | Application user | Observing the app-authorized native flow, no content/grant/config mutation; `givn/specs/access-shared-information/usecase.md`. |

No permanent leaf directory is created by Handoff itself. These complete topic-local contracts supply the stable identity/domain input for future changes. Native editing/sharing/calendar behavior and manual human assistance remain external/contextual, not new custom capabilities.

## Four ready change seeds

The user adopted this guarantee-based cut. A seed is input to a future `/givn-propose`, not an active change or permission to deploy. All named goals are covered explicitly; initial/returning routes do not substitute for the standalone existing-application reachability goal.

| Ready seed | Ship-alone guarantee | Dependencies / suggested start |
|---|---|---|
| [Recover declared hosted state](../../givn/ideation/infrastructure-growth/changes/recover-hosted-state.md) | Real existing-app coherent copy/independent bootstrap and verified supported replacement restore under its declared conditions. | First candidate when a real qualifying current app can be bound. No inherent photo/work dependency; never an empty generic backup fixture. |
| [Provide recoverable family photos](../../givn/ideation/infrastructure-growth/changes/recoverable-family-photos.md) | Native internet guest sharing plus complete persistence, photo-only 24-hour copy and verified supported recovery/use. | Uses hosted-state recovery only if consuming its delivered capability; otherwise can supply full photo recovery independently. Other-app proof is not photo proof. |
| [Reproduce usable personal work](../../givn/ideation/infrastructure-growth/changes/usable-personal-work.md) | Actual required work context/state/versions and permitted usable identities, not tools-only completion. | Independent of photo delivery. Recovery seed dependency exists only when an approved source consumes that capability. No photo-derived personal target. |
| [Bound an existing application's path change](../../givn/ideation/infrastructure-growth/changes/bounded-application-reachability.md) | Desired admitted/removed paths become effective without unrelated boundary or resource-grant changes. | Requires an existing target and requested change; depends on another access/recovery capability only if actually consumed. |

A sensible starting point is the hosted-state recovery proposal **if a real current app/state/procedure is available**. If not, do not fabricate one: the photo seed can be the first real end-to-end app/recovery delivery. Personal-work proposal/design can proceed independently with its actual approved state inputs. This is a dependency/start suggestion, not the user's release-priority commitment.

## Open inputs before implementation

The [question ledger](../../givn/ideation/infrastructure-growth/questions.md) retains complete decisions, rejected alternatives and parked inputs:

- **Approved personal-state sources (Q16):** actual required items, permitted sources/state versions or points, and independent usable bootstrap.
- **Qualified photo product/procedure (Q17):** native guest/authorization compatibility, coherent needed state and supported capture/restore.
- **Existing recovery target (Q21):** meaningful already-hosted application/state and its declared protection/recovery conditions.
- **Bounded path-change target (Q22):** actual existing app and requested before/after admitted/unwanted paths.

These inputs are not configurations already implemented or verified. They must be concrete in the respective normal proposal/design before real implementation and meaningful proof. Missing inputs cannot be replaced by mocks, empty data, references that regenerate secrets, unhonored settings or a weaker success guarantee.

## Verification and terminology

Reuse [the repository's native verification policy](../GIVN-VERIFICATION.md): exactly one resolving native binding per scenario, real VM/live evidence for end-to-end results, and no new Gherkin/Cucumber runner. Source/path-list evaluation is not proof of independent copy survival, supported restore, native authorized content or usable work/identity behavior. Existing target definitions were inventoried without running checks; their limited boot/evaluation coverage is not these new outcomes' runtime proof.

Contract identity/schema and relative diagram targets passed a throwaway structure check; fresh reviewers checked all diagram anchors and the six contracts' rules/examples/flows/guarantees. This is document/diagram proof only. Temporary render/helper surfaces were removed and no permanent verification scaffold was added.

Seven entries in the [topic term record](../../givn/ideation/infrastructure-growth/domain-terms.md) remain candidate. There are no confirmed terms to promote automatically and no rejected term entries to erase. Scoped collision evidence and its count limits remain recorded; the durable glossary is untouched. Do not confuse local persistence, provider snapshots, firewall-policy backup and application-state recovery, or claim unverified provider durability. The user's home lab and family datacenter may describe the same environment.

## Handoff record

The [resume state](../../givn/ideation/infrastructure-growth/session.md), [Frame](../../givn/ideation/infrastructure-growth/frame.md), [event narrative](../../givn/ideation/infrastructure-growth/eventstorming.md), [reviewed cut](../../givn/ideation/infrastructure-growth/use-case-definitions.md), [contracts](../../givn/ideation/infrastructure-growth/use-cases/) and [question history](../../givn/ideation/infrastructure-growth/questions.md) preserve the research, decisions and approvals.

The user confirmed the six-leaf/four-guarantee cut in Q18, operator promotion in Q19 and application-user promotion in Q20. Both exact preview diffs were applied; complete topic histories remain. Ready seeds have their own status lines so future proposal/archive operations can stamp them without rewriting their original decisions.

No active givn change, implementation plan/scaffold, application product/source selection, environment configuration, deployment, personal-data migration or raw secret operation was started by Handoff. When ready, run the normal proposal flow with one approved seed; do not treat ideation publication as implementation approval.
