# Domain terms: secure token keys

Status: confirmed and promoted 2026-10-17 (user) — the Event Storming term check confirmed all eleven candidates and the three reused durable terms. The user chose to promote all eleven to `docs/arc42/12-glossary.md`; the glossary now carries them with anti-terms. Promotion is vocabulary only and does not prove token behavior is implemented.

| Term | Status | Definition | Contrast | First use | Collision check |
|---|---|---|---|---|---|
| Security key | confirmed | A FIDO2/CTAP2.1 hardware authenticator the owner holds, which performs authentication without exporting its private key. | Hardware authenticator, not a software token, an OAuth access token, or a private key file. | frame.md:61 | `rg -i -c 'security key' docs/arc42/12-glossary.md givn docs hosts modules home README.md` excluding this topic: 0. `rg -i -c '\btoken\b' docs/plans`: 45 OIDC/access-token uses; those are not hardware authenticators, so this topic uses **security key** rather than **token**. |
| Daily security key | confirmed | The security key the owner carries and uses for routine authentication; in this topic the Swissbit iShield Key. | Daily-use key, not the separately stored backup. | eventstorming.md:25 | Same `security key` search: 0 outside topic. `rg -i -c 'daily security key'` outside topic: 0. |
| Backup security key | confirmed | The separately stored security key registered as its own credential; in this topic the Solo 2. | A separate registered credential, not a copy of the daily key. | eventstorming.md:28 | `rg -i -c 'backup security key'` outside topic: 0. |
| Enrollment | confirmed | The act of creating a personal-identity credential on a specific security key and recording its key handle in the identity declaration. | Local credential creation, not authorization at a remote. | eventstorming.md:25 | `rg -i -c '\benrol' docs/arc42/12-glossary.md givn docs hosts modules home README.md` outside topic: 0. |
| Token-held personal identity | confirmed | A personal identity whose private key is held and used by a security key, while the device keeps only a key handle. | Device-bound hardware identity, not a file-backed identity and not a copied private key. | frame.md:14 | `rg -i -c 'token-held'` outside topic: 0. The glossary already defines **Personal identity**; this term specializes it rather than replacing it. |
| Key handle | confirmed | The on-disk reference that lets the device ask a specific security key to authenticate; it is not a usable private key. | Device-bound reference, not a private key file and not a public key. | questions.md:15 | `rg -i -c 'key handle'` outside topic: 0. |
| Enrolled credential | confirmed | One security key's token-held personal identity, represented by its public identity and key handle. | One key's enrollment, not a remote grant and not a copy of another key's credential. | eventstorming.md:25 | `rg -i -c 'enrolled credential'` outside topic: 0. |
| File-backed personal identity | confirmed | The existing personal identity represented by `~/.ssh/id_ed25519` on `thiniel`, retained as the first-stage fallback. | Software-key identity, not a token-held identity; its private key remains on the device. | eventstorming.md:30 | `rg -i -c 'file-backed'` outside topic: 0. The glossary defines **Identity file** as the private key file; this term names the identity backed by that file, so the two do not collide. |
| Remote authorization | confirmed | The grant at a remote host that admits a specific public identity; it is separate from local enrollment. | Access grant at a remote, not the local credential and not the remote's account recovery policy. | eventstorming.md:15 | `rg -i -c 'remote authorization'` outside topic: 0. |
| Remote host | confirmed | An external system that authenticates the owner's public identity, such as GitHub or a server. | Authentication target, not the personal device and not the security key. | eventstorming.md:15 | `rg -i -c 'remote host' docs/arc42/12-glossary.md givn docs hosts modules home README.md` outside topic: 0. Generic **SSH host** uses in the repository describe connection entries, not this topic's authorization relationship. |
| Public identity | confirmed | The public half of an enrolled token-held personal identity, presented to a remote host for authorization; it grants nothing by itself. | Public authorization material, not the private key, not the key handle, and not the remote grant. | eventstorming.md:26 | `rg -i -c 'public identity' docs/arc42/12-glossary.md givn docs hosts modules home README.md` outside topic: 0. |

## Reused durable terms

These terms already exist in the durable glossary. The topic reuses their definitions and records the specialization; they are not new candidates.

| Term | Status | Definition in this topic | Source | Collision check |
|---|---|---|---|---|
| Identity declaration | reused durable term | The host's statement of which identity material it holds; in this topic it also records the token-held daily and backup credentials and their fallback order. It is a configuration record, not a grant. | `docs/arc42/12-glossary.md` **Identity declaration**; eventstorming.md:15 | `rg -i -c 'identity declaration' docs/arc42/12-glossary.md givn docs hosts modules home README.md` outside topic: 17 hits; the durable definition and the host modules already use it, so the topic reuses the name instead of introducing a competing one. |
| Personal identity | reused durable term | The device owner's own identity on a device; **token-held personal identity** is the specialization whose private key is held by a security key. | `docs/arc42/12-glossary.md` **Personal identity**; eventstorming.md:25 | `rg -i -c 'personal identity' ...` outside topic: 33 hits; no competing definition. |
| Identity file | reused durable term | The private key file an identity presents; distinct from the **file-backed personal identity** that owns it. | `docs/arc42/12-glossary.md` **Identity file** | `rg -i -c 'identity file' ...` outside topic: 43 hits; no collision. |

## Candidate domain sentences

- The owner enrolls the personal identity on the Swissbit, so the daily security key holds the token-held personal identity and `thiniel` keeps only its key handle.
- The owner authorizes the daily public identity at GitHub and at `adlerkopf`; enrollment alone grants no remote access.
- The Solo 2 is a backup security key, not a copy: it holds a separate enrolled credential and must be authorized independently at each remote.
- When the daily security key is unavailable, the owner may select the file-backed personal identity on `thiniel`, which still authenticates as the first-stage fallback.
- A lost daily security key's public identity is revoked at the remote, and daily use continues with the backup security key.

## Collision protocol — 2026-10-17

Commands run from the repository root, excluding `givn/ideation/secure-token-keys/**`:

- `rg -i -c 'security key' docs/arc42/12-glossary.md givn docs hosts modules home README.md`: 0 outside this topic.
- `rg -i -c 'token-held' ...`: 0; `rg -i -c 'key handle' ...`: 0; `rg -i -c 'enrolled credential' ...`: 0; `rg -i -c 'remote authorization' ...`: 0; `rg -i -c 'file-backed' ...`: 0; `rg -i -c 'backup security key' ...`: 0; `rg -i -c 'public identity' ...`: 0.
- `rg -i -c 'identity declaration' ...`: 17 hits, including the durable glossary's **Identity declaration** entry. This topic reuses that term and specializes it for the token-held credentials; no new name is introduced.
- `rg -i -c 'personal identity' ...`: 33 hits, including the durable glossary's **Personal identity** entry. This topic reuses that term and adds **token-held personal identity** as a specialization; no competing definition is introduced.
- `rg -i -c 'identity file' ...`: 43 hits, including the durable glossary's **Identity file** entry. This topic uses **file-backed personal identity** for the identity and leaves **Identity file** for the file itself.
- `rg -i -c '\btoken\b' docs/plans`: 45 hits, mostly OIDC access/refresh tokens. This is why the hardware authenticator is called a **security key**, not a token.

No aggregate is introduced. Security keys, the personal device, and remote hosts are external devices/systems; the identity declaration is a configuration record; a remote authorization is a grant.

## Term introduction test

Every candidate has a genus and differentia, a contrast pair, and a concrete sentence above. The user's Event Storming term check confirmed all eleven on 2026-10-17. Confirmation requires the user's verified name and the recorded collision check; both are present. The user then chose to promote all eleven to the durable glossary, and that promotion is applied. A rejected term keeps its definition and rejection reason.
