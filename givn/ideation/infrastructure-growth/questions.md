# Open questions: growing personal infrastructure

## Q1 — Desired outcome as the infrastructure grows

- Status: closed 2026-10-11 (user)
- Blocks: the topic's problem statement, vision, scope, and success criterion; Frame confirmation.
- Context: The user described a repository managing their laptops, workstations, servers, growing self-hosted home lab, and edge proxy. The repository documentation establishes its configuration purpose, but neither it nor a permanent specification establishes the outcome wanted from this discussion. Choosing an outcome determines which actor goals to model rather than assuming a repository redesign or another service deployment.
- Question: What should become possible—or stop being painful—as this setup grows?
- Options: none — this is an information request, not a choice between predefined directions. Illustrative answers could be adding a service without repeating access setup, replacing a failed server without losing its data, or keeping different machines consistent without erasing intentional differences. These examples are not proposed requirements or an exhaustive option list.
- Resolution: **Application onboarding with reused access and failed-server recovery with backups** because the user explicitly named those desired outcomes. A separate cross-machine consistency initiative is not selected because the user regards Nix and impermanence as the baseline addressing that concern; consistency is not rejected as a requirement. No particular application, access mechanism, or backup product was selected. The user's phrase "without losing its data" is retained as a desired outcome; the exact recovery guarantee remains unresolved in the recovery-guarantee question (Q3).

## Q2 — Confirm the home-lab discussion Frame

- Status: closed 2026-10-11 (user)
- Blocks: adopting the topic's goals and boundaries for personas and event storming.
- Context: The user has named application onboarding without repeated access work and failed-server replacement with data recovery from backups. They regard declarative Nix configuration and impermanence as the consistency baseline. The proposed Frame records those directions without choosing an implementation, assuming other stakeholders, or promising a recovery point that has not been established.
- Question: Should the Frame in `frame.md` guide the discussion, or should a named goal or boundary be revised first?
- Options:
  1. **Adopt this Frame** — model the owner/operator's two goals: add applications using reusable access arrangements, and recover applications and data on a replacement server. Nix and impermanence remain the consistency baseline; recovery guarantees and additional stakeholders remain open, not silently decided.
     In practice: explore how a newly added application gets the applicable access arrangements and how its data survives loss of the hosting server; do not launch a separate laptop-configuration redesign.
     Gain: a bounded basis for personas, events, and later use-case elaboration.
     Cost: goals outside this boundary require explicit reconsideration; data-loss and recovery-time commitments still need answers.
  2. **Revise a named goal or boundary first** — change the proposed problem, outcome, scope, or affected party before modeling it.
     In practice: if the goal must also include uninterrupted service during failure, add that availability goal explicitly rather than treating replacement from backups as failover.
     Gain: avoids modeling an incomplete or incorrect scope.
     Cost: delays affected modeling until the revision is settled.
- Resolution: **Revise the Frame first** because the user wants a family-serving datacenter, backups/recovery included in server/infrastructure setup, lower recovery-speed priority, and network plus laptop/workstation changes explicitly in scope. Rejected: adopting the narrower Frame unchanged, because its boundaries did not retain those configuration changes and its stakeholder inventory did not yet include family members. This authorizes revising the discussion record, not implementation or automatic advancement; the expanded Frame requires its own confirmation (Q5).

## Q3 — Data-loss and recovery-time guarantee

- Status: closed 2026-10-11 (assistant under explicit user delegation)
- Blocks: final recovery rules, success guarantees, and backup/recovery design; not recording the goal of failed-server recovery.
- Context: The user wants failed-server replacement without losing application data, with backups/recovery part of infrastructure setup. They have already stated that recovery speed is low priority; do not ask that direction again. The maximum tolerable loss of recent writes has not been stated, and the first concrete example is now the hosted photo application.
- Question: For the photo application, what is the maximum acceptable loss of recent photos or changes after complete server/storage failure?
- Options considered for the delegated planning assumption:
  1. **At most 24 hours of recent photo-application state lost** — use a 24-hour recovery-point target, with automated backups outside the failed server/storage and no strict recovery-time deadline.
     In practice: if the server/storage fails at 18:00, the available consistent recovery point must be no earlier than 18:00 the previous day; uploads/edits after that point may be lost.
     Gain: a simple daily-backup-oriented baseline suited to a family-operated home lab with low recovery-speed priority.
     Cost: recent photos can be permanently lost if the failed server held the only copy; a scheduled job does not meet the target unless a completed, restorable copy is sufficiently fresh.
  2. **At most one hour lost** — choose a one-hour recovery-point target.
     In practice: recovery after an 18:00 failure must include state from 17:00 or later.
     Gain: a smaller recent-data-loss window.
     Cost: more frequent application-consistent backup/durability work, with additional operational/storage activity; no evidence yet establishes that the family needs this stronger target.
  3. **No acknowledged application writes lost** — every photo or change reported as successfully saved must survive complete loss of the original server/storage.
     In practice: a photo accepted immediately before the failure must still be available after recovery.
     Gain: no recent-write loss within that failure scope.
     Cost: requires supported durability beyond the failed server at acknowledgement, rather than ordinary periodic backups; no selected application's support for that guarantee is known.
- Resolution: **Use a 24-hour photo-application recovery-point target as a planning assumption**, because the user said "make a sensible guess for this setup and go ahead" and recovery speed is already low priority. This is an assistant choice under delegation, not a measured tolerance or an explicit numerical preference supplied by the user. Rejected: one-hour target for lack of a demonstrated need justifying greater operating activity; zero acknowledged-write loss because it demands stronger supported durability than the periodic-backup baseline. Recovery stays manual with no numeric completion deadline. A completed, application-consistent copy must survive loss of the original server/storage; its actual recovery-point age determines whether the target is met. No backup product, destination, retention duration, or universal target for other applications is chosen. This is not zero data loss, a production guarantee, or evidence that any backup/restore currently works.

## Q4 — Parties affected by application access and recovery

- Status: closed 2026-10-11 (user)
- Blocks: completing the stakeholder inventory before use-case definition and confirming personas for any additional stakeholder type.
- Context: The user is established as the repository and infrastructure owner/operator. Nothing yet establishes whether another person uses these applications, depends on their data, or is entitled to decide who may access them. Those interests could change the access and recovery rules; they are not invented in the Frame.
- Question: Who besides the owner/operator, if anyone, uses or depends on these applications or their data?
- Options: none — parked information request, not a predefined persona choice.
- Resolution: **Family members are affected stakeholders** because the user explicitly says their family relies on the infrastructure and should not have to use cloud services. A sole-owner stakeholder model is not adopted because it omits those dependents. No individual persona, access authority, or application requirement is inferred from this answer.

## Q5 — Confirm the expanded family-infrastructure Frame

- Status: closed 2026-10-11 (user)
- Blocks: adopting the revised goals, vision, stakeholders, and scope as the basis for further modeling.
- Context: The user revised the earlier narrow Frame to include a family-serving self-hosted environment, backups and recovery as part of server/infrastructure setup, low recovery-time priority, and continued network/laptop/workstation changes. The revised Frame retains application onboarding with reused access and data recovery after server failure. It leaves specific network and personal-device outcomes and acceptable data loss unresolved rather than excluding or inventing them.
- Question: Should this expanded family-infrastructure Frame guide the discussion, or should a named part be revised first?
- Options:
  1. **Adopt the expanded Frame** — pursue self-hosted alternatives for the family, reusable application access, and recoverable infrastructure, while keeping server, network, and personal-device changes in scope. Recovery speed is secondary, but no data-loss allowance is granted.
     In practice: setting up a server includes its backup/recovery provisions; a later laptop setup or network change remains a legitimate topic rather than being rejected as outside scope.
     Gain: a shared direction that includes the family's needs and the requested breadth.
     Cost: a broader topic requires eliciting distinct network and personal-device goals before cutting use cases; accepting this Frame alone does not select applications or technologies.
  2. **Revise a named part first** — correct the vision, stakeholders, priority, or scope before relying on the Frame.
     In practice: if network changes should be a separately discussed topic, identify that boundary rather than having it silently folded into application onboarding.
     Gain: avoids building later models on a wrong boundary or priority.
     Cost: delays affected modeling until the correction is settled.
- Resolution: **Adopt the expanded Frame** because the user explicitly said "Adopt this revision" after its vision, stakeholders, scope, priorities, unknowns, and authority limits were shown. Rejected: revising a named part before modeling, because the user accepts the revised record as the discussion basis. The adopted scope includes family-serving infrastructure, built-in backup/recovery, low recovery-speed priority, and network plus personal-device changes. No data-loss allowance, technology choice, implementation, deployment, finalized use-case contract, or artifact promotion is approved. Later scope revisions require revisiting affected models.

## Q6 — Outcomes wanted from network changes

- Status: closed 2026-10-11 (assistant integrating confirmed user direction)
- Blocks: actor goals and use-case definition for the network portion of the expanded scope.
- Context: The user explicitly wants to retain changes to network configuration in this discussion. Neither that statement nor the existing ingress design records identifies the desired new actor outcome. The Frame therefore includes network work without assuming a topology redesign or restricting it to onboarding applications.
- Question: What concrete outcome should a network change make possible or improve for you or your family?
- Options: none — parked information request. No technical approach or actor outcome has been chosen.
- Resolution: **Make intended applications reachable through their per-application internet or family-VPN-only paths**, as explicitly specified by the user in the reachability/persona discussion and reinforced when VPN was assigned to application requirements rather than base device setup. This answers the currently named network outcome; a further unnamed topology redesign is not an unresolved prerequisite to modeling it. Rejected: one global exposure policy, separate internet/VPN personas, and treating VPN enrollment as a universal personal-device setup goal. Network changes remain in scope; future additional actor goals can be added when stated rather than silently excluded or invented. No firewall implementation, topology, VPN product, or extra access rights are selected.

## Q7 — Outcomes wanted from laptop/workstation setup changes

- Status: closed 2026-10-11 (user)
- Blocks: actor goals and use-case definition for personal-device setup in the expanded scope.
- Context: The user explicitly wants to retain laptop/workstation configuration/setup changes. They still consider declarative Nix and impermanence a consistency baseline, which does not settle what changes they want on those devices. The Frame includes this work without inventing a fresh-install, development-environment, or family-access goal.
- Question: What concrete outcome should a laptop or workstation setup change make possible or improve?
- Options: none — parked information request. No technical approach or actor outcome has been chosen.
- Resolution: **Reproduce the usual working environment**, because the user explicitly names that goal for laptops/workstations. Rejected: treating VPN access as the defining personal-device setup outcome; the user places it under application requirements. VPN software/configuration may still be selected on a device when needed by an application, but is not a mandatory base-environment gate. Reuse the existing owner/operator persona and per-device feature composition; do not invent a new desktop/application choice or require identical Linux/macOS configurations. The scope of nonreconstructible personal state remains a separate question (Q15).

## Q8 — Confirm the hands-on infrastructure owner/operator persona

- Status: closed 2026-10-11 (user)
- Blocks: creating and using the owner/operator persona as a review lens for events and use cases.
- Context: The adopted Frame establishes the owner/operator's configuration authority and priorities, but Frame adoption is not persona confirmation. A refreshed inventory found no project-level or sibling-topic persona files to reuse. The proposed segment is the hands-on owner/operator, distinguished by authority to change infrastructure and personal-device configuration and the ability to evaluate configuration and recovery evidence; it is not a separate persona for each host or tool.
- Question: Should the following owner/operator profile be adopted as a persona review lens, or should a named part be revised first?
- Proposed stable core:
  - Role: hands-on owner/operator of the family-serving self-hosted infrastructure and their personal devices.
  - Authority boundary: changes server, network, application-access, and personal-device configuration. This does not assume unrestricted authority over other family members' personal data.
  - Evaluation capability: judges configuration changes and evidence that access works and application data is recoverable; does not treat a successful backup job as proof of restore.
  - Own vocabulary: applications, Nix, declarative configuration, impermanence, access setup, backups, recovery, servers, network, laptops, workstations — terms used in this discussion.
  - Success criterion: can make intended configuration changes and establish whether the resulting behavior and recovery meet the agreed requirements.
- Proposed dated topic stance, 2026-10-11: for this topic, prioritizes reusable application-access setup and recoverable family application data, includes backup/recovery in infrastructure setup, and treats recovery speed as secondary. This stance is separate from the persona's stable core.
- Options:
  1. **Adopt this operator persona** — use the stated stable core when reviewing the owner's goals, without creating separate per-host or per-tool personas. Topic-specific priorities go in dated stance records rather than redefining the stable role.
     In practice: when a server replacement flow is modeled, this persona asks for recovered application data, not merely a successful reinstall or a green backup-job report.
     Gain: an explicit operator review lens grounded in the adopted goals.
     Cost: additional operator segments require a real authority, evaluation, or vocabulary distinction; this profile does not speak for family members' usability or privacy needs.
  2. **Revise a named part first** — correct the role, authority, evaluation capability, vocabulary, or success criterion before using it.
     In practice: if another person decides application-access policy, narrow this persona's authority instead of assuming the operator decides everything.
     Gain: prevents an incorrect authority or evaluation assumption from entering later reviews.
     Cost: operator-persona creation and use wait for the correction.
- Resolution: **Adopt this operator persona** because the user explicitly said "Adopt this profile" after its stable core, topic stance, and review-only authority were shown. Rejected: revising a stable-core field before use, because the user accepts the proposed profile. Create the topic-local owner/operator persona as a review lens; no project-level promotion, implemented permissions, or configuration changes are authorized. This does not adopt a family-member persona or decide family members' authority.

## Q9 — Family members' responsibility for shared applications and infrastructure

- Status: closed 2026-10-11 (user)
- Blocks: establishing family persona authority boundaries and deciding whether any family operator matches the confirmed operator segment or needs a distinct segment.
- Context: The adopted Frame establishes that family members rely on the self-hosted applications; it does not establish whether they also operate shared systems. The owner/operator persona is now confirmed, but it cannot stand in for family members' authority or abilities. Actual responsibility for configuration, shared access policy, or recovery distinguishes an operator role from application use without assuming technical skill or age.
- Question: Do any family members share responsibility for administering the applications or infrastructure, or do they only use the applications you operate?
- Options: none — an information request about existing responsibilities, not a proposal to grant permissions. For example, adding an application, configuring shared access policy, or restoring a server is operation; using an application or managing one's own content does not by itself establish infrastructure administration.
- Resolution: **Family members use applications operated by the owner/operator and may need their support using them**, because the user explicitly stated those responsibilities. Shared family administration is not adopted: the user says family members only use the applications. This does not determine individual application permissions, technical skill, preferred vocabulary, support tooling, or response-time commitments. Family-persona confirmation remains separate (Q10).

## Q10 — Confirm the family application-user persona

- Status: closed 2026-10-11 (user)
- Blocks: creating and using a family-member persona when reviewing events and use cases.
- Context: The user establishes that family members only use the applications the owner/operator runs and may need support using them. A refreshed project/sibling-topic inventory found only this topic's confirmed operator persona; its configuration authority differs from family members' application-use responsibility, so it is not a matching segment. One family application-user segment is proposed; needing occasional help does not itself establish another authority, evaluation, or vocabulary segment.
- Question: Should this family application-user profile be adopted as a review lens, or should a named field be revised first?
- Proposed stable core:
  - Role: family member using applications operated by the infrastructure owner/operator.
  - Authority boundary: uses the application functions available to them; does not administer the shared applications or infrastructure. Specific application permissions remain to be defined.
  - Evaluation capability: can judge whether their intended application task succeeds and whether assistance lets them continue; this is a proposed review capability, not evidence that all family members have identical technical skill. No infrastructure-diagnosis capability is assumed.
  - Own vocabulary: application, access, my data, help — proposed user-facing terms, not observed quotes from family members. No requirement to use infrastructure terminology.
  - Success criterion: can accomplish their intended application task, with assistance when needed, without taking on infrastructure administration.
- Proposed dated topic stance, 2026-10-11: uses the family-serving self-hosted applications instead of being required to use cloud applications, and may rely on the owner/operator for help using them. No support product, channel, service-level commitment, or specific application is selected.
- Options:
  1. **Adopt this application-user persona** — use one family-use review lens with the stated authority and proposed task-based evaluation/vocabulary; do not label family members nontechnical or create separate segments merely by device or need for help.
     In practice: when an application-use flow is unclear, the family perspective checks whether help enables the intended task rather than expecting the person to administer the hosting server.
     Gain: family-use and assistance needs are considered separately from the operator's configuration concerns.
     Cost: this broad segment does not yet distinguish specific applications or family preferences; any later split needs evidence of an authority, evaluation, or vocabulary difference.
  2. **Revise a named field first** — adjust the proposed evaluation criterion, vocabulary, or role description while preserving the already stated application-use-only responsibility unless a new reason changes that direction.
     In practice: replace "my data" with terminology actually used in the family's applications if that phrase does not fit.
     Gain: a better-fitting family review lens.
     Cost: family-persona creation and use wait for the correction.
- Resolution: **Adopt this application-user persona** because the user explicitly said "Adopt this profile" after the stable core, dated topic stance, and authority limits were shown. Rejected: revising a named field before use, because the user accepts the displayed profile. Create the topic-local family application-user review lens; no implemented permissions, support tooling, response-time promise, project-level promotion, or configuration change is authorized. The accepted vocabulary is a modeling lens, not evidence of verbatim family terminology.

## Q11 — Concrete family task for the first event narrative

- Status: closed 2026-10-11 (user)
- Blocks: grounding the first family-facing event chain in an actual task rather than inventing applications, outcomes, policies, or aggregate boundaries.
- Context: The Frame and both persona profiles are confirmed. The family relies on applications operated by the owner/operator, with possible help using them, but no concrete family task has been named for this discussion. Existing technical plans do not establish which family outcome should anchor the first narrative; network and personal-device goals remain separately in scope.
- Question: What is one concrete family task you want the self-hosted setup to support?
- Options: none — an information request for a real example, not application selection or delivery-order approval. Illustrative tasks include sharing a family photo album, accessing shared documents, or managing a household calendar; none is assumed to be needed.
- Resolution: **Start with sharing a family photo album**, because the user explicitly chose that as the first narrative. They also confirmed accessing shared documents and managing a household calendar as valid tasks, with more applications expected later. Rejected: treating the first example as the only in-scope task; the user explicitly retained the others. This selects a discussion starting point, not a photo product, implementation order, or application-internal redesign.

## Q12 — Audience for sharing a family photo album

- Status: closed 2026-10-11 (user)
- Blocks: the access rule and viewer actors for the first photo-sharing event narrative; do not invent sharing permissions or a consistency boundary before this is settled.
- Context: Sharing a family photo album is the selected first infrastructure example; document access, household calendars, and future applications remain in scope. The Frame establishes family users but not whether an album may also be shared outside that group. A reusable access setup must distinguish general family-application access from permission to view a particular album; current edge-authentication plans do not answer that domain rule.
- Question: Who should be able to view a shared photo album in this first narrative?
- Options:
  1. **Family-application users only** — viewers must already be authorized users of the family's applications; a share does not grant outsiders access.
     In practice: a family member with application access can view the shared album; a friend without that access cannot view it merely because someone forwards its address.
     Gain: one existing audience boundary and less external exposure.
     Cost: occasional outside viewers must first be admitted to the family-application audience; album-only guest access is not covered.
  2. **Selected outside viewers as well** — an album can be shared with selected people who do not otherwise have access to the family applications. How they are identified or invited remains a later question.
     In practice: a family member shares a holiday album with a friend without giving that friend general access to the family datacenter.
     Gain: useful album-only sharing without broad application access.
     Cost: model guest access and its withdrawal separately; recipients may retain copies even after viewing access is withdrawn.
  3. **Public sharing of explicitly chosen albums as well** — an album may intentionally be made viewable without an individual viewer authorization.
     In practice: a published album address can be opened by anyone it reaches, while unpublished albums are not thereby public.
     Gain: lowest-friction sharing with a broad audience.
     Cost: photos may spread beyond intended recipients; making the album private again cannot be assumed to remove copies already retained.
- Resolution: **Selected outside viewers as well** because the user chose option 2 and explicitly placed guest-sharing functionality in the selected, hosted photo application. Rejected: family-application users only, because invited outsiders must be supported without general family-application access; public sharing as a required goal, because the user chose selected recipients rather than unrestricted publication. This repository must host/configure the application and provide compatible infrastructure reachability, not build album permissions, guest invitations, or sharing/revocation logic. No photo product, invitation mechanism, network exposure, or privacy guarantee beyond that audience choice is selected. Revocation must not be described as undoing retained copies.

## Q13 — Infrastructure reachability for invited photo viewers

- Status: closed 2026-10-11 (user)
- Blocks: the infrastructure access path in the photo-hosting narrative and the eventual edge/firewall requirements; guest authorization remains owned by the hosted photo application.
- Context: The user wants selected outside viewers to use the photo application's existing sharing feature, not custom guest-sharing development. The infrastructure must not turn album-only access into a requirement for general family-application access. The choice of reaching an internet-facing application versus joining a private network is not settled by the audience decision; it changes the viewer's required setup and the application's exposure.
- Question: Should invited viewers reach the photo application from an ordinary internet connection without joining your private network, or must they establish private-network access first?
- Options:
  1. **Ordinary internet access; the application controls album access** — the photo application's required guest-facing web endpoints are reachable without joining the home-lab network or having general family-application access. The hosted app still determines which photos the viewer may see.
     In practice: a friend opens the application's shared-album address from their phone's browser; only the application's own guest-access requirements apply.
     Gain: no per-guest network enrollment and a compatible low-friction sharing flow.
     Cost: expose the necessary web surface to internet traffic and maintain its security; edge authentication must be compatible with the app's guest flow. A reachable endpoint does not make the album public.
  2. **Private-network access first** — a viewer must establish an approved private connection, such as a VPN, before the application can be reached; the application still controls album access.
     In practice: a friend first sets up the private connection, then opens the shared-album address; the album invitation alone is not sufficient for reachability.
     Gain: the guest-facing application need not be generally internet reachable.
     Cost: per-viewer connection provisioning and support, including people invited to just one album; private-network access must not imply broad access to other infrastructure or applications.
- Resolution: **Ordinary internet access; the application controls album access** because the user explicitly chose ordinary internet access. Rejected: private-network access first, because invited viewers must not need private-network enrollment before opening a shared album. Required guest-facing web endpoints must be reachable without general family-application access, while the hosted application owns authorization. This does not make all albums public, authorize a blanket edge-authentication bypass, expose administrative endpoints, select a photo application, or authorize deployment.

## Q14 — Confirm the invited album-viewer persona

- Status: closed 2026-10-11 (user)
- Blocks: representing selected outside recipients in persona reviews of the photo-hosting event narrative.
- Context: The user has confirmed selected outside album recipients, ordinary internet reachability, and application-owned guest authorization. The reuse inventory contains owner--operator (configuration authority) and family--application-user (use of the family's hosted applications). A narrower album-recipient segment is proposed because its authority is limited to a selected shared album without general family-application access, not merely because the person is outside the family; no technical-skill or support assumption is made.
- Question: Should the following invited album-viewer profile be adopted as a review lens, or should a named field be revised first?
- Proposed stable core:
  - Role: recipient invited to view a shared photo album in an application hosted by the owner/operator.
  - Authority boundary: views the selected album subject to the application's rules; has no general family-application or infrastructure access. Editing, downloading, resharing, and other permissions are not assumed.
  - Evaluation capability: judges whether the intended shared album can be viewed; no hosting, network-administration, or backup-evaluation capability is assumed.
  - Own vocabulary: album, photos, shared address, access — proposed terms for the review lens, not observed quotes from recipients.
  - Success criterion: can view the intended album within the access granted by the application.
- Proposed dated topic stance, 2026-10-11: opens the application's shared-album address over an ordinary internet connection without private-network enrollment or general family-application access. The hosted application owns guest authorization; this repository does not build it.
- Options:
  1. **Adopt this album-viewer persona** — represent the recipient's album-only authority separately from operator configuration and family-application use.
     In practice: a proposed access path that requires joining the home-lab network does not meet this topic's confirmed recipient requirement, even if it works for a family user.
     Gain: guest reachability and access boundaries have an explicit review lens.
     Cost: the profile deliberately says nothing about permissions beyond viewing; those must follow the application's configured sharing capability, not invented guest rights.
  2. **Revise a named field first** — correct the proposed role, evaluation criterion, or vocabulary before using the profile, without re-opening confirmed reachability or audience rules absent a new reason.
     In practice: replace "shared address" with "invitation" if that better describes the recipient's experience while leaving invitation implementation to the hosted application.
     Gain: a better-fitting recipient review lens.
     Cost: recipient-persona creation and use wait for the correction.
- Resolution: **Revise to a general application-user persona**, because the user explicitly says the persona should not be limited to album viewing and distinguishes internet-accessible applications from family-VPN-only applications. Rejected: adopting the album-viewer draft unchanged, because it mistakes resource permissions/application context for a narrow persona boundary. Reuse and generalize the already confirmed application-user segment: its authority remains use of granted application functions, not infrastructure administration; reachability and invited-resource scope are topic stances/application policies. No separate album, internet, or VPN persona is created. The existing stable persona ID is retained. Photo guests' ordinary internet access and application-owned authorization remain confirmed; other applications need not share that exposure policy.

## Q15 — Personal state included in reproducing the usual working environment

- Status: closed 2026-10-11 (user)
- Blocks: the personal-environment success guarantee: whether reproducing intended software/settings is sufficient or the goal also promises a usable restored working-data context.
- Context: The user names reproducing the usual working environment as the personal-device goal and keeps VPN under application requirements. The repository documents per-host software/settings composition separately from persistence paths such as Projects, dev, SSH material, and keyrings; declaring or retaining those paths does not establish recovery on a replacement device. The delegated photo application's 24-hour recovery-point target does not decide personal-device data or credential handling.
- Question: Does reproducing your usual working environment include restoring the personal working state needed to resume work, or is that state supplied by a separate workflow?
- Options:
  1. **Reproduce software/settings; supply personal state separately** — the environment flow establishes the intended tools/settings and preserves already available state, while working files and required credentials come from a separate declared prerequisite/workflow.
     In practice: a replacement machine gets the usual shell/editor configuration, but project files and required identities must be made available separately before the corresponding work can resume.
     Gain: a bounded reproducible-environment contract without silently adding personal-data recovery.
     Cost: it cannot alone promise a fully restored workspace; that prerequisite/workflow still needs an explicit owner and usable source.
  2. **Restore the usable working environment including required personal state** — the flow must also make the needed working files/state and identities available or re-established before claiming readiness.
     In practice: after preparing a replacement machine, the owner can resume the intended project with its required files and access, rather than just launch a configured editor.
     Gain: an end-to-end work-ready outcome.
     Cost: identify required state, its authoritative/recoverable sources, and safe credential bootstrap; no blanket credential copying or photo-data recovery target may be assumed.
- Resolution: **Usable working environment, including required personal state**, because the user explicitly chose that outcome. Rejected: software/settings-only readiness with working state supplied outside this goal, because launching configured tools is not the accepted end-to-end guarantee. Required working files, application state, and authorized identity access must be made available or re-established through approved sources and supported procedures before readiness is claimed. This is not blanket credential copying, a promise to reconstruct unavailable data from declarations, a personal-data recovery-point target, mandatory VPN enrollment, a data migration, or deployment. The photo application's 24-hour assumption is not applied to personal state.

## Q16 — Approved sources for required working state and identities

- Status: open
- Blocks: actual source bindings and end-to-end recovery/reproduction proof in the future personal-environment change; not the accepted state-inclusive goal or its use-case sizing.
- Context: The user requires a usable usual environment including working state and permitted identities. Tracked configuration identifies locally retained workspaces/application state and credential references, plus sync clients, but does not demonstrate a surviving source for every required item or independent key bootstrap. Private/out-of-repo backups and actual contents were not inspected. This inventory must be supplied before implementation claims readiness; missing input must fail rather than downgrade to software-only setup.
- Question: What approved source supplies each required working-state or identity item for the selected device?
- Options: none — a parked operating/design inventory request, not selection of a new backup product or permission to copy all credentials. Each item needs its owner-authorized source and required state/version/point, plus the bootstrap access that makes it usable; existing authoritative storage, supported retrieval, suitable backup restoration, or permitted identity re-establishment may differ by item.
- Resolution: pending. The 24-hour photo target is not a personal-data allowance. This question does not require a new topology, support application, or secret store, and no real data transfer or credential enrollment is authorized by its record.

## Q17 — Qualified hosted application and supported recovery procedure

- Status: open
- Blocks: product-specific hosting, native guest-flow integration and real application-state backup/restore proof in the future photo-application change; not the already accepted actor outcomes.
- Context: The user wants a hosted photo application to supply sharing/guest authorization, with selected outside viewers using ordinary internet access. A 24-hour photo recovery-point target is the delegated planning baseline, and recovery requires coherent state plus independent bootstrap/copy survival. No photo product or its required persistent-state/recovery procedure has been selected; infrastructure cannot substitute custom sharing logic or arbitrary file copying for that supported behavior.
- Question: Which qualified hosted photo application and supported capture/restore procedure will supply the accepted photo-sharing and recovery requirements?
- Options: none — parked product/operating input for the normal proposal/design. Qualification must establish the application's native selected-recipient flow, compatible intended reachability, required coherent state, permitted identity/bootstrap inputs and supported restoration. No package/version or URI convention is guessed here.
- Resolution: pending. A future change must select and exercise real interfaces before claiming the photo service is usable/recoverable; no mock provider, generic empty backup, or config-only ready state satisfies the accepted guarantee.

## Q18 — Confirm the leaf mapping and standalone deliverable cut

- Status: closed 2026-10-11 (user)
- Blocks: approving the proposed permanent use-case mapping and change-seed boundaries before Handoff publication; persona promotion choices remain separate and no change starts automatically.
- Context: All six goal contracts passed sizing and elaboration reviews; actor/vocabulary/extension-label corrections are applied, and required source/product choices remain honestly open for proposal/design. Each goal must own a separate permanent leaf: application availability, existing-application reachability change, application-state protection, hosted recovery, complete personal-work reproduction, and observing shared-information access. A seed-cut audit found that initial/restore routes did not cover an independent existing-application path change, so the proposed cut contains four complete deliverables rather than claiming that goal was already covered by photo setup.
- Question: Should the proposed leaf mapping and four standalone deliverable guarantees in `use-case-definitions.md` become the Handoff cut, or should a named boundary be revised first?
- Approval subject:
  - Every reviewed `!` case keeps its stable ID and future `givn/specs/<use-case-id>/usecase.md` leaf; no case is buried as a capability under another goal.
  - Recover declared hosted state: real selected existing-app coherent copy/independent bootstrap and verified replacement restore under its declared conditions.
  - Provide recoverable family photos: qualified native photo app usable by family/selected internet invitees, coherent persistent state, independently surviving 24-hour photo point, and supported verified restore/native use.
  - Reproduce usable personal work: actual required tools/settings/state/versions and permitted usable identities, never software-only success or a photo-derived personal target.
  - Change an existing application's paths: a deliberate bounded change actually changes admitted/removed paths without unintended boundaries/grants changing, not just initial setup or recovery.
  - Dependencies are conditional on consuming a delivered capability, not forced by naming order. Current-app/source/procedure bindings are mandatory before implementation; no fake existing app or empty generic fixture may substitute.
- Options:
  1. **Adopt this Handoff cut** — retain six leaf contracts and the four proposed guarantee-based seeds, with the documented true/conditional dependencies and open operating inputs.
     In practice: a photo app that starts but has no usable required recovery point is not a finished photo deliverable; a configured editor missing required work is not a finished personal-environment deliverable.
     Gain: bounded independently shippable outcomes with no uncovered reachability goal or config-only intermediate completion.
     Cost: four separate deliverables require their own real bindings/proof; the mapping does not promise a universal platform in one change or remove proposal/design source selection.
  2. **Revise a named boundary first** — change a seed's guarantee/coupling or leaf boundary before publishing the handoff record.
     In practice: merge existing-state recovery with photo delivery if the photo app should be the first real qualifying recovery target, while retaining the full copy/restore/guest-use guarantee rather than shipping a generic backup scaffold.
     Gain: delivery boundaries better fit the desired first real target.
     Cost: revisit affected coverage/dependencies before seeds can be ready; no intermediate state may violate accepted readiness/protection rules.
- Resolution: **Adopt the leaf mapping and four standalone deliverable cut** because the user explicitly said "Adopt this cut" after the full goals, guarantees, conditional dependencies and boundaries were shown. Rejected: revising a named boundary first, because the user accepts the proposed record. The six leaf identities and four guarantees are confirmed Handoff inputs, not a product/source selection, release order, deployment, data transfer, persona/term promotion or automatic change start. Publication/ready seeds still await the remaining per-file persona-promotion decisions.

## Q19 — Project-level owner/operator persona or topic-local retention

- Status: closed 2026-10-11 (user)
- Blocks: the owner/operator persona's Handoff promotion choice; no project persona file is created before this decision.
- Context: The owner/operator core was confirmed and used as a review lens in this topic. The project-level collection `givn/personas/` is currently absent. An exact proposed new-file diff is recorded in `promotions/owner--operator.diff`; it preserves the confirmed role/authority/evaluation/vocabulary/success criterion, adds the core's confirmation provenance and dated validated topic stances, and leaves complete topic history intact. Draft/superseded assessments are not turned into global defaults.
- Question: Should the owner/operator persona be promoted to `givn/personas/owner--operator.md` using that exact diff, or remain topic-local?
- Approval subject: hands-on owner/operator of family infrastructure and personal devices; configuration authority without unrestricted family-data rights; judgment of working configuration/access and recoverability rather than green jobs; existing Nix/infrastructure vocabulary; intended changes whose behavior/recovery meet agreed requirements. Dated stances preserve reusable access, per-app internet/VPN policy, manual family help, delegated photo-only 24-hour planning target, and state-inclusive personal readiness. None is an implemented permission, a universal data-loss target, or a product/source choice.
- Options:
  1. **Promote the validated persona** — create the proposed project-level stable core and dated record entries so future topics can reference a central persona ID/base instead of copying a biography.
     In practice: a future application-hosting change can reuse the operator's authority/recoverability lens; it does not inherit a 24-hour target for every dataset.
     Gain: discoverable consistent project-wide reuse with topic stances kept separate from the stable core.
     Cost: maintain the project persona record and preserve context when adding future dated entries; approval applies to this file/diff only.
  2. **Keep it topic-local** — retain the confirmed persona and full records in this topic; create no project collection/file for it.
     In practice: later ideation can still explicitly reuse this topic's operator base, but there is no central project file to consult.
     Gain: no project-wide persona artifact yet; the record remains scoped to this topic.
     Cost: future work must locate/reference the topic base rather than the central collection; do not invent a duplicate merely because it is local.
- Resolution: **Promote the owner/operator persona using the exact proposed diff** because the user explicitly said "Promote it" and then "continue". Rejected: topic-local-only retention, because the user chose central project reuse. Created `givn/personas/owner--operator.md` from the approved new-file payload with unchanged stable core, confirmation provenance and dated validated stances; the complete topic history remains intact. This promotes only this file: no application-user promotion, infrastructure/data change, topic publication, ready seed or active change is authorized by this decision.

## Q20 — Project-level general application-user persona or topic-local retention

- Status: closed 2026-10-11 (user)
- Blocks: the application-user persona's final Handoff promotion choice; owner/operator promotion is already approved/applied and does not decide this file.
- Context: The user adopted the family application-use profile and then explicitly generalized it beyond albums/internet/VPN personas. Its stable ID remains family--application-user. The exact proposed new project file diff is in `promotions/family--application-user.diff`; all five stable-core fields are unchanged, with confirmation/generalization provenance and dated validated topic stances. The full topic-local history remains intact. No application-user project file exists yet.
- Question: Should the general application-user persona be promoted to `givn/personas/family--application-user.md` using that exact diff, or remain topic-local?
- Approval subject: an application user, family member or invited recipient within actual grants; uses available functions without operating shared infrastructure; judges task success and useful assistance without assumed diagnostic skill; uses the confirmed application/access/my-data/help vocabulary as a lens, not attributed interview quotes; completes the intended task without becoming an operator. Dated records keep family-only support context, per-app internet/VPN policy, native guest sharing and photo-only disclosed recovery risk separate from the core. No wider data/grant/admin rights, support deadline, persona split or universal RPO is added.
- Options:
  1. **Promote the general application-user persona** — create the exact proposed project-level file for central reuse of this same segment and dated records.
     In practice: a later document/calendar-hosting topic can reuse the task-success/access lens without creating separate internet/VPN users or granting photo guests access to other apps.
     Gain: consistent discoverable consumer-side review alongside the promoted operator persona.
     Cost: maintain the central dated record and keep resource permissions/topic risks separate from stable authority; approval applies to this file/diff only.
  2. **Keep it topic-local** — retain this confirmed general profile and history in the topic, with no new project application-user file.
     In practice: later topics can explicitly reuse this topic's base while the central collection contains only the operator persona.
     Gain: no broader application-user artifact yet; current topic review use remains valid.
     Cost: future reuse must locate/reference this topic rather than the central collection; its absence does not justify inventing duplicate persona segments.
- Resolution: **Promote the general application-user persona using the exact proposed diff** because the user explicitly said "Promote it" after that file's unchanged core, dated context and consequences were shown. Rejected: topic-local-only retention, because the user chose central consumer-lens reuse. Created `givn/personas/family--application-user.md` from the approved new-file payload, retaining the stable ID and complete topic history. Both per-file promotion choices and the mapping/four-guarantee cut are now confirmed, so the readable topic and ready seed records can be published. This does not promote candidate terms, select products/sources, transfer working data, deploy applications or automatically start a givn change.

## Q21 — Real existing application and recovery requirements for the hosted-state seed

- Status: open
- Blocks: actual target/procedure/protection bindings and native proof for the future recover-hosted-state change; not its confirmed standalone guarantee.
- Context: The user adopted a seed that recovers a real already-hosted application's state, not a generic empty backup framework. Source inventory documents local persistence and proposed backups but does not identify an exercised independent coherent copy/bootstrap/restore for that seed's target. A real application's required state and native supported procedure must be concrete before implementation; no universal photo 24-hour target is assigned to it.
- Question: Which existing hosted application, complete required state and declared protection condition will be the real target of the hosted-state recovery change?
- Options: none — a parked target/operating inventory for proposal/design. The chosen target must have a meaningful supported state capture/restore and permitted inputs that can survive original-server/storage loss; qualification cannot be replaced by a dummy directory or source-path assertion.
- Resolution: pending. If no qualified current target is available, do not claim a generic recovery delivery; the photo seed may supply its full actual recovery itself under the approved conditional-dependency cut.

## Q22 — Actual existing application and requested bounded path change

- Status: open
- Blocks: target/scope and real admission/removal proof for the future bounded-application-reachability change; not the accepted application-specific network outcome.
- Context: The standalone reachability seed must change an already available application's requested paths, not claim coverage merely from creating a new photo route or returning a route after restoration. Neither an actual target nor a particular requested before/after change was selected during ideation. Existing native grants and unrelated boundaries must be known sufficiently to check the bounded change.
- Question: Which already available application and requested permitted-path change should the standalone reachability change implement?
- Options: none — parked proposal/design target selection. The requested application-specific internet/private paths and unwanted paths must be explicit, with actual native access checks; no new topology, connection product or resource permission follows by default.
- Resolution: pending. Initial setup/recovery route handling does not satisfy this independent goal, and no passive exposure setting or unevidenced path change is a finished deliverable.
