# Use Case Definition: growing personal infrastructure

Status: sizing review passed after mechanical actor/vocabulary corrections. Proceed to one-at-a-time elaboration; this cut selects no implementation or release order.

The cut reuses the confirmed Frame, operator/application-user personas, the state-inclusive personal-environment decision (Q15), per-application reachability (Q6/Q13/Q14), and the delegated photo recovery-point target (Q3). Exact approved working-state/source bindings remain an operating/design input (Q16), not a software/settings-only alternative.

## Leaf goals and boundaries

Every proposed case is level `!`, with one primary actor and one observable outcome. All are separate future permanent leaf candidates, not capabilities nested under a single catch-all host/server goal. No summary use case is needed for this initial cut; the topic itself is not a permanent use case.

| Stable use-case ID | Actor's goal | Primary actor | Nature | Single outcome / closure | Boundary and affected stakeholders |
|---|---|---|---|---|---|
| make-application-available | Make a self-hosted application available to its intended users | Owner/operator | Changing | The selected application is usable under its agreed hosting requirements. | Hosting includes intended reachability, persistent application state, and recovery provisions; do not declare backup protection without usable-copy evidence. Native app functions are supplied by the selected app, not built here. Owner, family users, and invited recipients where relevant. |
| adjust-application-reachability | Change an application's permitted access paths | Owner/operator | Changing | The existing application is reachable through its requested paths and not unrequested paths. | Internet versus family-VPN-only is application-specific, not a persona or base-device rule. No new resource permission or unrelated topology redesign. Owner and affected application users. |
| preserve-recoverable-application-state | Preserve a usable recovery point for an application | Owner/operator; Supporting: Backup agent for the Owner/operator | Changing | A usable surviving recovery point meets the application's declared protection requirement at assessment. | Supported coherent capture, independence from original server/storage, honest failure/staleness. Photo target is 24 hours under delegation; no blanket target or new backup product. Owner and affected data users. |
| recover-hosted-applications | Restore hosted applications after server failure | Owner/operator | Changing | Intended users can use the recovered applications at the accepted recovered state. | Replacement setup, supported restoration, data/access checks and intended route re-establishment belong to the one recovery outcome. A source/restore/verification failure is not success. Photo recovery-point age is measured against the failure, not the later restore completion. Owner and affected users. |
| reproduce-working-environment | Reproduce the usual usable working environment on a chosen personal device | Device owner | Changing | The owner can resume usual work on the selected device. | Required tools/settings, working files/application state and authorized identities are conditions of this one readiness outcome. Retrieval/bootstrap are subfunctions, not permission to clone every credential. Approved inputs must be supplied; missing state means not ready. Owner; no extra device/VPN persona. |
| access-shared-information | Access information shared with me through a hosted application | Application user | Observing | The user can view the intended information within the grant supplied by the application. | Infrastructure delivers the supported native flow through the permitted path; it does not create sharing grants, implement photo/document/calendar logic, edit content, or grant general family/infrastructure access. Family and invited recipients. |

## Sizing checks and mutation ownership

- **One goal / one actor:** each Goal is one active-verb outcome. Configuration, persistent application state, backup coverage, and route handling are necessary setup/recovery conditions, not alternative actor goals silently joined by "and".
- **Closure:** an owner can stop after an application is available, a reachability change is effective, a recovery point is usable, recovered applications are usable, or their usual work can resume. A reader can stop after receiving the intended information. Missing required state or protection is not an acceptable intermediate "ready" state.
- **Goal-shaped:** names do not own a proxy, backend, store, panel, browser, or CLI. Reachability and backup mechanisms advance these actor outcomes; no goal is cut by channel or platform.
- **Level discipline:** `!` leaves own any eventual capabilities directly. No direct capability is owned by a summary. No leaf's contract is a catalogue of unrelated administrator goals.
- **Mutation containment:** hosted-runtime setup belongs to application availability; changes to access-path policy belong to reachability; copied state belongs to protection; restoring runtime/data and returning intended access belongs to recovery; personal setup/state/bootstrap changes belong to usable environment reproduction. The information-access case observes existing permitted information and owns no content/grant/configuration mutation.
- **Preconditions:** authorization, required specifications and supported external application/source procedures must exist or be supplied before the corresponding operation. The successful resulting environment, backup, or application availability is established by the flow, never assumed as a precondition.
- **Independence:** actor goals and outcomes remain meaningful if configuration tooling, operating systems, backup products, or application implementations change. Protection has the owner as primary actor; a supporting agent carries delegated refresh/capture work without becoming another primary actor or persona.
- **Relationships:** no leaf-to-leaf Includes/Extends relationship is asserted merely because operations share a subfunction. Any mandatory shared fragment remains level `-` at ideation; optional failure handling must protect the original case's guarantee rather than introduce another goal.

## Shared subfunctions and external context — not new permanent leaves

| Element | Treatment | Reason |
|---|---|---|
| Apply a declared reachability requirement during initial setup or recovery | `-` shared infrastructure subfunction | The standalone reachability-change leaf covers deliberately changing an existing application's paths; initial setup/recovery consumes the same declared rule without inventing another actor goal. |
| Establish recovery coverage for a newly made-available application | `-` setup subfunction tied to the protection contract | App readiness must honor required recovery provisions, while the protection leaf owns the copied-state transition. No seed may ship an unused backup flag or claim recoverability from a schedule alone. |
| Retrieve/restore required personal state and establish permitted identity access | `-` subfunctions of full personal-work readiness | The user rejected configuration-only completion. Partial sources/bootstrap do not close the reproduction goal; no independent permission expansion is inferred. |
| Native album sharing, document editing, calendar management | External hosted-application behavior | Confirmed family tasks select qualified applications and integration examples, not custom app functionality or permanent capabilities implemented here. |
| Family application-use assistance | Manual external interaction / conditional recovery of an application-use problem | The owner may help users. No custom help desk, response SLA, or outsider support obligation is inferred. If guidance can recover the original access goal, it can be an extension tied to that step; guidance about external app functions stays external. |

## Advisory persona value assessment

These assessments apply confirmed review lenses, not interviews, satisfaction scores, human-selected priorities, or release sequencing.

| Goal | Owner/operator lens | Application-user lens |
|---|---|---|
| Make an application available | High: grow the setup without repeated common access work. | High: obtain a self-hosted alternative that is actually usable. |
| Change application reachability | High: keep intended public/private boundaries effective. | High where it affects access; a guest must not need general family access for the photo flow. |
| Preserve recoverable application state | Critical: a green job or same-disk persistence is not recovery proof. | Critical for data preservation; recent loss within the delegated photo window remains a disclosed risk. |
| Restore hosted applications | Critical: usable state and correct intended access, not merely a running service. | High: regain access and backed-up information; no fast-recovery commercial SLA assumed. |
| Reproduce usual working environment | High: resume work with actual files/state and identity access, not installed tools alone. | Not a direct family/guest requirement; do not invent authority or preferences for the owner's workspace. |
| Access shared information | High: hosted apps fulfill the family's reason for avoiding mandatory cloud apps. | High: view the intended granted information without operating infrastructure or receiving wider rights. |

## Open inputs and exclusions

- Q16 remains the approved required-working-state/source inventory before personal-environment implementation and proof. Source references, local retention, and sync are not demonstrations that current data can be restored after a loss.
- Photo application and supported backup/recovery procedures, concrete host/source bindings, and actual native guest-flow endpoints are selected during the appropriate proposal/design, not fabricated here.
- The photo target is a planning assumption for that application only. No personal-data or all-application data-loss window, retention duration, automatic failover, retry design, new monitoring platform, or blanket credential migration is chosen.
- No app editing/sharing logic, general support service, employer/client-data authority, or new topology is added to the topic by this cut.
- Permanent mapping, persona promotion choices and standalone guarantee-based change seeds are Handoff records requiring explicit user confirmation later. No leaf directory, change artifact, code, deployment, or promotion is created by this draft.

## Use Case Definition phase review — 2026-10-11

The fresh-context reviewer accepted all six goal-shaped `!` leaves, their closure/value and mutation boundaries, observing native-information access, external application/manual-support boundaries, and state-inclusive personal readiness. Availability with required recovery coverage and complete work readiness are single actor outcomes with necessary subfunctions, not forced `+` summaries. Applied its two mechanical corrections: owner-primary protection with a supporting backup agent, and normalized persistent-application-state wording. No new human fork or change to approved intent was found. Proceed to one-at-a-time Use Case Elaboration; value assessments remain advisory rather than release priorities.

## Native verification constraints for later specifications

Read-only baseline research and `docs/GIVN-VERIFICATION.md` establish that this repository binds scenarios to actual native `@check:`, `@host:`, or `@deploy:` targets, with exactly one resolving binding per scenario. No Gherkin/Cucumber runner is added. E2E outcomes require real boot/live evidence; a path-list/evaluation assertion is not backup, identity, restored-workspace, or network-isolation proof.

Existing source defines evaluation/unit/lint checks and limited VM boot smoke targets; no actual check was run for this ideation and source inspection does not prove the new actor outcomes. Current tracked target definitions do not provide end-to-end proof of independent app-data recovery, personal state/identity reproduction, or the requested public/private/native-app flows. External/private tests or live operations were not audited. Control-plane firewall-state backup tests are not application-state restore proof. Future proposals must bind to/add meaningful actual targets rather than invent names or re-pin incidental option/path-list/source-text assertions.

## Use Case Elaboration phase gate — 2026-10-11

All six contracts are elaborated in `use-cases/` with the supplied schema, rules, concrete illustrative examples, actor/system steps, protected extensions, guarantees, persona critiques, actual diagram references and Markdown scenario skeletons. A fresh-context reviewer accepted the contracts without an outcome fork. Applied its two mechanical fixes: removed unused supporting actors from availability, and disambiguated alternative extension labels at a shared main step. A throwaway structure/link check confirmed all required schema headings, stable file identities and existing diagram targets; the reviewer independently checked all eight referenced heading anchors. This is document proof, not native behavior or test execution.

## Confirmed Handoff records — published

The user adopted the six-leaf/four-guarantee cut (Q18) and both exact persona promotions (Q19/Q20). The readable topic is published at `docs/ideation/infrastructure-growth.md`; four seed files under `changes/` have `Status: ready`. These are inputs to later normal proposal/spec work, not permanent leaf creation, implementation authority, release commitment or an automatically started change.

### Use-case-to-permanent mapping

Each reviewed `!` goal maps to its own future permanent leaf, through the normal proposal/spec flow. No capability is nested under another goal merely to reduce the document count.

| Goal (stable identity) | Future permanent leaf |
|---|---|
| Make an application available (`make-application-available`) | `givn/specs/make-application-available/usecase.md` |
| Change application reachability (`adjust-application-reachability`) | `givn/specs/adjust-application-reachability/usecase.md` |
| Preserve recoverable application state (`preserve-recoverable-application-state`) | `givn/specs/preserve-recoverable-application-state/usecase.md` |
| Restore hosted applications (`recover-hosted-applications`) | `givn/specs/recover-hosted-applications/usecase.md` |
| Reproduce usable usual work (`reproduce-working-environment`) | `givn/specs/reproduce-working-environment/usecase.md` |
| Access granted shared information (`access-shared-information`) | `givn/specs/access-shared-information/usecase.md` |

### Confirmed guarantee-based change seeds

Seed boundaries are independent deliverable guarantees, not one seed per case or an infrastructure/settings scaffold. The mapping below covers all six cases explicitly; setup/recovery's use of a reachability rule does not silently cover the independent existing-application change goal.

| Ready seed | End-to-end ship-alone guarantee | Use-case coverage | Dependencies and suggested start |
|---|---|---|---|
| Recover declared hosted state (`recover-hosted-state`) | For a real identified already-hosted application, a supported coherent copy and independent bootstrap survive the original server/storage loss; a supported replacement restores verified state and intended use under that application's declared conditions. | Protection and hosted recovery for the selected existing application. | First proposal candidate when a real qualifying current app/state/procedure can be bound. No inherent photo/work seed dependency. Never replace the missing app/procedure with an empty generic fixture. |
| Provide recoverable family photos (`recoverable-family-photos`) | A qualified hosted photo app is usable by family and selected internet invitees through native sharing, with necessary persistent state, an independently surviving coherent point meeting the photo 24-hour condition, and verified supported restoration/native use. | Availability and shared-information access, plus photo-specific protection/recovery integration. | Consumes hosted-state recovery only if actually using its delivered capability. Otherwise can deliver the full guarantee itself; generic/other-app recovery proof is not photo proof. Bind Q17 before implementation. |
| Reproduce usable personal work (`usable-personal-work`) | On the specified device the owner resumes the specified usual work with actual required files/app state at approved versions/points, intended tools/settings, and permitted usable identities; missing inputs never become software-only success. | Complete personal working-environment reproduction. | Independent of the photo seed. Hosted-state recovery is a dependency only if an actual approved source uses that capability. Bind Q16 and independent bootstrap before implementation; no personal photo-RPO inheritance. |
| Change an existing application's paths (`bounded-application-reachability`) | A requested bounded change on a real existing app becomes effective: desired paths are usable, obsolete/unrequested paths are not admitted, and unrelated boundaries/resource grants are not changed. | The standalone adjust-reachability goal, not just initial setup or returning a route after recovery. | Requires an actual already available target and specified change. Reuses the photo/access implementation only if that capability is actually consumed; otherwise independent. No invented topology or unprotected config-only app readiness. |

An independent seed-cut audit found the first three guarantees viable with actual bindings/conditional dependencies and identified missing standalone reachability coverage. The fourth seed applies that correction without adding an unrelated route-change outcome to photo delivery. The user adopted this cut; start suggestions remain conditional dependency guidance, not a release-order commitment.

### Confirmed persona promotions

- Owner/operator (`owner--operator`): user approved promotion in Q19; `givn/personas/owner--operator.md` is created from the exact approved `promotions/owner--operator.diff`, preserving the stable core and context-only dated records. Full topic history is unchanged.
- General application user (stable ID `family--application-user`): user approved Q20; `givn/personas/family--application-user.md` is created from the exact approved `promotions/family--application-user.diff`, unchanged core/context-only records, central base b7dca9bc. Full topic history is unchanged; no album/internet/VPN segment is created.
- Both per-file promotions are complete. The approved readable topic and ready seeds are published; no active change, deployment, raw-data operation or durable-term promotion is started.

### Terms

All seven term entries remain candidate, with definitions/contrasts/sentences and scoped collision evidence; some broad counts are incomplete. No confirmed term is auto-proposed/promoted to the durable glossary and no rejected entry is erased. Candidates stay topic-local until the relevant checks/meaning and promotion are explicitly decided. The published Handoff leaves the durable glossary unchanged.

### Open operating inputs preserved into future seeds

- Q16 — actual required personal state/identity inventory, approved sources/versions and independent bootstrap availability.
- Q17 — qualified photo product/native guest flow and supported coherent capture/restore procedure.
- Existing-application seeds also need their real target, required state/native procedure/protection condition or desired bounded path change before implementation; source declarations do not prove those runtime inputs. Record those concrete choices during the normal proposal/design rather than fabricate them.
- Native proof must exercise the selected application's/work context's real results with resolving targets; no source/path-list/evaluation/mock echo is a substitute.
