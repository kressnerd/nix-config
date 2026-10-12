# Use case: preserve-recoverable-application-state

Status: elaborated domain draft; no backup product, destination or real copy selected/proven.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Backup agent for the Owner/operator, when protection refresh is delegated.

## Goal
The Owner/operator preserves a usable surviving recovery point meeting an application's declared data-protection requirement.

## Trigger
The Owner/operator requests a protection refresh, directly or through an already commissioned requirement becoming due.

## Preconditions
- The Owner/operator is authorized to protect the specified application state.
- The application's required coherent state and supported capture/restore procedure are identified; photo-specific qualification is an operating input (open: Q17).
- Protection requirements identify the original server/storage failure boundary, required recovery-point condition, permitted source/destination scope, and bootstrap material needed to use a surviving copy.
- Permitted operating inputs can be supplied independently of a copy already being declared protected; no new successful copy is assumed.

## Main flow
1. Actor Owner/operator supplies the protection request or its commissioned requirements; System identifies the required permitted application state and assessment condition.
2. Actor Owner/operator makes approved capture/bootstrap inputs available; System establishes a supported coherent capture without broadening data or credential access.
3. Actor Owner/operator authorizes preservation, with delegated work where configured; System creates a copy and the recovery evidence needed outside the original server/storage failure boundary.
4. Actor Owner/operator assesses the returned evidence; System distinguishes captured state/time, usable consistent content, surviving bootstrap availability and the application's target from a job's finish/success status.
5. Actor Owner/operator obtains the result; System reports protection satisfied only for a usable surviving point that meets the declared condition, preserving truthful information about failed attempts and previous candidates.

## Extensions
- 1: Required state/procedure has not been qualified → report the missing operating definition rather than treating arbitrary paths as a consistent capture; protects meaningful recoverability (open: Q17).
- 2: Source or bootstrap material is unreadable/unauthorized/unavailable → report the unmet prerequisite and do not fabricate captured state; protects data authority and truthful protection.
- 3: Copy creation fails or the copy shares the original failure boundary → retain any earlier usable evidence and report the unsuccessful attempt; protects surviving recoverability rather than deleting the last valid copy.
- 4a: A copy cannot be used coherently under the supported restore procedure → report it unusable; protects recoverability even if the job exited successfully.
- 4b: The usable point misses the declared recovery-point condition → report the target miss, with the actual surviving candidate if any; protects truthful data-loss expectations.
- 5: A newer attempt failed but an older candidate remains usable → assess that candidate on its own capture time and condition; protects accurate availability without relabeling the failed attempt as success.

## Rules
- A protected recovery point is supported by coherent usable state and required bootstrap access surviving loss of the original server/storage.
- Local impermanence persistence, a same-storage snapshot, a source-path reference, sync configuration or a green job status does not alone prove that condition.
- Assess the actual state capture time, not the copy-job finish time or a rewritten destination file timestamp.
- The delegated photo recovery-point target is at most 24 hours at assessment/failure reference, not zero acknowledged-write loss. No other application's or personal-device target is inferred.
- A new application is not represented as protected until a usable required copy exists; a schedule or flag alone is insufficient.
- Failed refresh does not authorize deleting the last usable surviving copy, copying unrelated data, exposing secret contents, or inventing a retry/retention/monitoring product.
- Supported procedure and actual content evidence determine usability; a nonempty backup directory is not the success condition.

## Examples
Illustrative values describe the known protection condition, not current copies.

- At 18:00, a usable coherent photo recovery point captured at 02:00 the same day is sixteen hours old and meets the delegated 24-hour target. Later uploads/edits are not promised by that point.
- A job finishes at 18:00, but its captured photo state is from 16:00 the previous day. That point is twenty-six hours old at assessment and misses the target despite the recent finish time.
- A fresh copy contains photo originals but lacks the metadata/inputs required by the application's supported restore. It is not reported usable.
- A refresh fails while an independently surviving older usable copy remains. The failed attempt is reported; the older point's age/usability determines its actual status.

## Minimal guarantee
Unsuccessful or inadequate protection is reported honestly without granting extra access, disclosing raw bootstrap secrets, or silently destroying an existing usable surviving recovery copy.

## Success guarantee
A usable surviving recovery point meets the application's declared protection requirement at assessment.

## Personas
- Owner/operator (`owner--operator`): advisory critique — the returned point must actually be usable after the stated loss and assessed by capture time, not job-green or path membership.
- Application user (`family--application-user`, generalized): advisory critique — recent data loss within the photo assumption remains disclosed; protection must not pretend every latest upload survived.

## Capabilities
- none — future native capture/assessment capabilities and meaningful verification targets are selected in proposal/spec.

## Interactions
- none — no unsupported backup API, new secret store or arbitrary schedule endpoint selected.

## Includes
- none.

## Extends
- none.

## Out of scope
- Restoring users' applications after an actual failure — `recover-hosted-applications`.
- Initial complete application availability — `make-application-available`; its recovery provisions must honor this protection condition rather than shipping an unused flag.
- Reproducing personal work state/identities — `reproduce-working-environment`; it receives no photo loss allowance from this contract.
- Implementing native application data/sharing behavior — the external application's goals.

## Diagram
See the rendered [setup and recovery-copy canvas](../eventstorming.md#canvas-establish-setup-and-create-recovery-copies) and its assessed-candidates read model. The owner is the primary actor; delegated capture is supporting work.

## Scenario skeletons
- Given declared photo protection requirements and a coherent copy captured sixteen hours before assessment that survives the original failure boundary, When the returned evidence is assessed, Then the 24-hour condition is met without promising later uploads.
- Given a job that finished recently but state captured twenty-six hours earlier, When the point is assessed, Then the target miss is reported.
- Given a successful file-copy result that lacks required coherent restore state, When recoverability is checked, Then the copy is not represented as usable.
- Given an older usable surviving copy and a failed newer refresh, When the operation completes, Then the failure is truthful and the older candidate is retained/assessed without a false new-copy claim.

These are contract skeletons, not executed backup proof or `.feature` deltas. Actual consistency, survival and restoration need real native VM/live interaction evidence; static path lists or mock echoes do not establish the outcome.
