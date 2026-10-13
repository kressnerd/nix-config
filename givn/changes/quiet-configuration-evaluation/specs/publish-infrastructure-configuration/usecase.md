# Use case: publish-infrastructure-configuration

## Level
!

## Actors
- Owner/operator

## Goal
The Owner/operator publishes the declarative configuration publicly without
disclosing operational data, and every host still builds and deploys from the
values held outside the public repository.

## Trigger
The Owner/operator prepares the configuration repository for public publication,
or records a change to it.

## Preconditions
- The repository is the operator's declarative configuration for the hosts.
- Every operational value a host needs — address gateway hardware address resolvers and port — is available to the operator outside the public repository.
- The operator holds whatever is needed to publish the repository and to deploy the hosts.

## Main flow
1. Actor Owner/operator supplies a host's operational values from outside the repository; System builds and deploys that host with exactly those values.
2. Actor Owner/operator records configuration and documentation changes; System keeps the recorded content free of operational values and uses documentation-range placeholders or empty values for the host network defaults.
3. Actor Owner/operator attempts to record a revision; System refuses any revision that would record an operational value, a per-host private-value file, or an unencrypted secret file.
4. Actor Owner/operator publishes the repository; System yields a checkout that evaluates and passes its checks without any private value and reports no diagnostic the operator must triage.
5. Actor Owner/operator confirms the published history; System records no operational value in it.

## Extensions
- 1: A host's operational value is missing from the private source → the deploy refuses rather than falling back to an operational default; protects the separation between public content and operational values.
- 2a: A default would carry an operational value → the guard refuses the revision; protects the recorded content.
- 3a: A per-host private-value file or an unencrypted secret file would be recorded → the guard refuses the revision; protects the separation.
- 4: A checkout that holds no private values cannot evaluate → the repository is not publishable as it stands; report the unmet requirement rather than publishing it.
- 5: The rewrite has not run → the history still records the values; report it rather than treating the repository as safe to publish.

## Rules
- Operational values never live in the public repository: neither its recorded content nor its published history carries an address, gateway, hardware address, provider resolver or non-standard port that identifies the operator's infrastructure.
- The host network defaults are documentation-range placeholders or empty values. A missing private value fails loudly; it never falls back to an operational value.
- Per-host private-value files are held outside the repository.
- A revision that would record an operational value, a per-host private-value file, or an unencrypted secret is refused, both before it leaves the operator's machine and on the repository's continuous integration.
- A secret is encrypted before it is recorded.
- Separation is not encryption: operational values are kept out of the public repository, they are not encrypted.
- A setting whose release default the configuration superseded is stated explicitly at a value the operator chose — a value that relocates a device's data is carried out without discarding it — so an evaluation of the repository reports no migration, release-mismatch or unrecognised-output diagnostic to triage. The flake declares only outputs the checker interprets.

## Examples
- The operator deploys the home server with its real LAN address supplied from outside the repository; the repository records `192.0.2.10` as the default. A reader of the repository learns the schema but not the address.
- A reader clones the repository and runs its checks; they pass because every host evaluates with documentation-range placeholders and no private value.
- The operator stages a document that contains the real LAN address; the guard refuses the revision and names the offending location.
- The operator's private notes file and per-host value files exist only on the operator's machine and are never recorded.
- The operator runs the history rewrite and confirms the published history records none of the values; until then the repository is not treated as safe to publish.
- The operator's flake check prints nothing to triage: the laptop's home profile states the settings whose release defaults were superseded, and its browser profile lives under the XDG config directory.

## Minimal guarantee
A repository state that records an operational value, a per-host private-value
file, or an unencrypted secret is not published, and a host build never
silently substitutes an operational default for a missing private value.

## Success guarantee
The published configuration discloses no operational data, and every host builds
and deploys with the values held outside the repository.

## Personas
- owner--operator

## Capabilities
- operational-data-separation
- quiet-configuration-evaluation

## Interactions

| Capability | Consumer action | E2E scenario |
|---|---|---|
| operational-data-separation | the operator deploys a host with the values supplied from outside the repository | A host booted with values supplied from outside the repository uses those values |
| quiet-configuration-evaluation | the operator checks or builds the configuration | A booted device reproduces its identity surface from a single release |

## Includes
- none

## Extends
- none

## Out of scope
- Rotating, regenerating or assigning credentials and addresses on live providers and hosts — the operational response to a disclosure, not repository or configuration state.
- Encrypting operational values: they are kept out of the repository, not encrypted.
- Changing any host's network behaviour, topology, firewall or tunnels.
- The infrastructure-growth goals: application availability, per-application reachability, application-state protection, hosted recovery, personal working-environment reproduction, and shared-information access.

## Diagram
None — no ideation canvas exists for this goal; it was introduced by the change.
The change's design record carries the architecture.
