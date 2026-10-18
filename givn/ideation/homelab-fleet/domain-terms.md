# Domain terms: operating the home datacenter fleet

Status: candidate terms only. No term is confirmed and no durable glossary
entry is changed. The durable glossary already defines `Host`; this topic
reuses it and does not redefine it.

| Term | Status | Definition | Contrast | First use | Collision check |
|---|---|---|---|---|---|
| Fleet | candidate | A declared set of hosts operated as one environment under one owner, with shared naming, identities and update rules. | A fleet, not a single host and not an unmanaged collection of machines. | frame.md:1,164 | `grep -ic "fleet" docs/arc42/12-glossary.md` = 1 incidental use in the Colmena-hive row, no competing definition; `grep -ric "fleet" docs --include='*.md'` = 18 across existing prose; `grep -ric "fleet" givn --include='*.md'` = 59, including this topic. Broad counts are scoped evidence, not full clearance. |
| Accepted host | candidate | A host whose base system, storage layout, network attachment and declared roles are present and checked, not merely declared. | An accepted host, not a configured host and not a host that merely boots. | eventstorming.md:55,163 | `grep -ic "accepted host" docs/arc42/12-glossary.md` = 0; `grep -ric "accepted host" docs --include='*.md'` = 0; `grep -ric "accepted host" givn --include='*.md'` = 1, this topic only. |
| Storage pool | candidate | A btrfs filesystem spanning one or more encrypted storage devices and presented as one unit for a declared data class. | A storage pool, not a single storage device, a partition or an NFS export. | eventstorming.md:40,63 | `grep -ic "storage pool" docs/arc42/12-glossary.md` = 0; `grep -ric "storage pool" docs --include='*.md'` = 0; `grep -ric "storage pool" givn --include='*.md'` = 1, this topic only. |
| Storage device | candidate | A physical SSD or NVMe drive that belongs to exactly one storage pool. | A storage device, not a partition, a LUKS mapping or the pool. | eventstorming.md:16,63 | `grep -ic "storage device" docs/arc42/12-glossary.md` = 0; `grep -ric "storage device" docs --include='*.md'` = 0; `grep -ric "storage device" givn --include='*.md'` = 1, this topic only. |
| Edge route | candidate | A declared mapping from a public endpoint to one selected home service through the edge tunnel, with its admission boundary. | An edge route, not an application resource grant and not a raw firewall port. | eventstorming.md:40,69 | `grep -ic "edge route" docs/arc42/12-glossary.md` = 0; `grep -ric "edge route" docs --include='*.md'` = 0; `grep -ric "edge route" givn --include='*.md'` = 0 outside this topic. |
| Unlock material | candidate | The credential or authority that releases a host's encrypted root: a Tang response, a TPM binding or the retained passphrase. | Unlock material, not a backup of the encrypted data and not a personal identity. | eventstorming.md:41,56 | `grep -ic "unlock material" docs/arc42/12-glossary.md` = 0; `grep -ric "unlock material" docs --include='*.md'` = 0; `grep -ric "unlock material" givn --include='*.md'` = 0 outside this topic. |
| Update window | candidate | The declared time range in which a host may apply updates and reboot, including its order relative to other hosts. | An update window, not a backup window and not a recovery deadline. | eventstorming.md:75 | `grep -ic "update window" docs/arc42/12-glossary.md` = 0; `grep -ric "update window" docs --include='*.md'` = 0; `grep -ric "update window" givn --include='*.md'` = 2, this topic only. |
| Host recovery | candidate | Restoring a host's declared role and persistent system state on replacement hardware. | Host recovery, not application-state recovery and not an ordinary reboot. | eventstorming.md:12,85 | `grep -ic "host recovery" docs/arc42/12-glossary.md` = 0; `grep -ric "host recovery" docs --include='*.md'` = 0; `grep -ric "host recovery" givn --include='*.md'` = 0 outside this topic. |
| Health signal | candidate | An observed host, pool or edge condition used to decide whether the owner is alerted. | A health signal, not a user report and not a successful monitoring job. | eventstorming.md:41,86 | `grep -ic "health signal" docs/arc42/12-glossary.md` = 0; `grep -ric "health signal" docs --include='*.md'` = 0; `grep -ric "health signal" givn --include='*.md'` = 0 outside this topic. |
| Service role | candidate | The assignment of one infrastructure service (DNS, Tang, Headscale, mail MTA, monitoring) to an intended host. | A service role, not an application feature and not a user grant. | eventstorming.md:15,50 | `grep -ic "service role" docs/arc42/12-glossary.md` = 0; `grep -ric "service role" docs --include='*.md'` = 0; `grep -ric "service role" givn --include='*.md'` = 0 outside this topic. |

## Reused durable term

This row is a reuse reference, not a new confirmation by this topic. The
candidate table above is the only term table this topic proposes; `Host` was
confirmed in the durable glossary before this topic and is cited, not
re-confirmed.

| Term | Status | Reuse |
|---|---|---|
| Host | confirmed in the durable glossary (prior confirmation, not this topic) | "One declared machine configuration under `hosts/<host>/` mapped in the flake to a `nixosConfiguration` or `darwinConfiguration`." This topic uses `host` for both the declaration and the running external system; the contrast is stated in the event partners ("Host — external system" versus the configuration record). No new `Host` entry is created. |

## Candidate domain sentences

- A storage-device failure degrades the storage pool; it does not by itself make the exported data unavailable.
- An accepted host has its base system, storage layout, network attachment and declared roles present; a host that merely boots is not accepted.
- An edge route admits a selected service; it does not grant a user the right to use that service's resources.
- The update window for `pronix` precedes the window for `tinix001`, so the Tang host is running when `pronix` reboots.
- Host recovery restores the host's declared role and system state; it does not restore application data, which is a separate guarantee.

## Evidence limits

These are candidate terms defined from the Frame and the event chain. The
collision checks are working-tree searches with gitignore respected. They do
not cover private inputs, live hosts or external vocabulary. The broad `fleet`
counts are not a claim that the term is unused elsewhere; they record where
the word appears without a competing definition.
