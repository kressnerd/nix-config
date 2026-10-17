# Questions: secure token keys

## Q1 — Which owner outcome must the tokens serve first?

- Status: closed 2026-10-17 (user)
- Blocks: the Frame's goal and vision; every later use case, device-scope decision, and change seed.
- Context: the owner holds a Swissbit iShield Key and a Solo 2 and wants to use them. The repository declares no FIDO2, PAM U2F, or `ed25519-sk` behavior. The same two keys can back several unrelated guarantees, and each has a different lockout and recovery cost. The permanent capability `permitted-identity-selection` (a device reaches private repositories with the identity material it declares) already exists for file-based SSH keys; device login and secret unlock have no equivalent today.
- Question: which owner outcome must the tokens serve first — device privilege authentication, remote identity, web-account authentication, or secret/disk unlock?
- Options:
  1. **Device privilege authentication.** The owner touches a token to log in or to run privileged commands on Linux devices.
     In practice: on `thiniel`, `sudo` prompts for a touch; a stolen password alone no longer yields root. greetd login can require the token.
     Gain: protects the local privilege boundary against a stolen password or unattended session; no private key material changes.
     Cost: requires a registered backup token before the factor becomes mandatory; PAM misconfiguration can lock the owner out of their own laptop; macOS login/sudo is not covered by PAM U2F.
  2. **Remote identity.** The owner's SSH private keys live in the token; private repositories and servers authenticate with a device-bound credential.
     In practice: `~/.ssh/id_ed25519_swissbit` becomes a key handle; `git push` to a private repository requires the token and a touch; no usable private key exists on disk.
     Gain: a stolen disk or copied home directory yields no usable SSH identity; maps directly onto the existing `permitted-identity-selection` capability.
     Cost: every server and GitHub account must register both tokens; the work Mac needs a compatible OpenSSH and agent setup; losing both tokens means re-registering every remote; resident-key slots are finite.
  3. **Web-account authentication.** The tokens act as WebAuthn/passkey authenticators for browser accounts.
     In practice: GitHub or another web account asks for a security key, and the owner touches the Swissbit; the Solo 2 is enrolled as the backup.
     Gain: phishing-resistant second factor for the accounts that matter; mostly account-side enrollment, little device configuration beyond udev.
     Cost: this repository can only supply device recognition, not the accounts' enrollment; the work Mac and personal browsers must both be covered; account recovery policy remains external.
  4. **Secret or disk unlock.** The token participates in unlocking SOPS age material or a LUKS volume.
     In practice: `adlerkopf` unlocks its LUKS volume with a token touch at the console, or the SOPS age key is derived from the token instead of a file.
     Gain: secret material at rest is bound to hardware the owner carries.
     Cost: `thiniel` is OPAL SED, not LUKS, so FIDO2 disk unlock does not apply there; headless servers need physical presence; a lost token can strand a disk; age support needs a compatible plugin and a recovery key, and `age-plugin-yubikey` is PIV-only.
  5. **All of the above, staged.** The tokens become the owner's general strong-authentication device, with one surface delivered first.
     In practice: SSH identity first, then WebAuthn enrollment, then sudo; each stage ships with a tested backup path.
     Gain: one coherent hardware-backed owner identity instead of disconnected experiments.
     Cost: a larger scope and more lockout surfaces; the first outcome still has to be named, and the Frame cannot treat "all" as a single goal.

- Resolution: **All, staged** because the owner wants the two tokens to back their general strong-authentication posture across device privileges, remote identity, web accounts, and secret/disk unlock, delivered one surface at a time rather than as one isolated experiment. The stage order remains open (Q2). Rejected: device privilege authentication alone because it covers one local boundary and carries the highest lockout cost without delivering the identity or account benefits the owner wants; remote identity alone because it would leave local privilege, web accounts, and secret material untouched despite the owner choosing the broader scope; web-account authentication alone because it is mostly account-side enrollment and would not make the tokens part of the device configuration; secret/disk unlock alone because platform support is partial (`thiniel` uses OPAL SED, not LUKS) and physical presence limits headless use. "All" includes the disk/secret surface, whose applicability is limited to LUKS hosts and to a compatible age mechanism; it does not promise FIDO2 disk unlock on `thiniel`.

## Q2 — Which surface ships as the first standalone stage?

- Status: closed 2026-10-17 (user)
- Blocks: the Frame's vision and the first change seed; which existing capability is extended first; the order in which lockout and recovery risks are taken on.
- Context: Q1 put all four token surfaces in scope, staged. Each stage must be usable on its own, with a tested recovery path, and must not leave a half-enabled auth path behind. The repository already has a verified file-based SSH identity capability (`permitted-identity-selection`: a device reaches private repositories with the identity material it declares) and no token-aware login, PAM, age, or disk-unlock behavior. The first stage also establishes the common substrate — token recognition and udev access — that every later stage depends on.
- Question: which surface must the first stage deliver end to end?
- Options:
  1. **Remote identity.** Token-held SSH identities replace or supplement the file keys used for private repositories and servers.
     In practice: on `thiniel`, `git push` to a private repository prompts for a touch; the token holds the identity and the disk holds only a key handle. Both tokens are registered on GitHub and the relevant servers.
     Gain: extends an already verified capability; no local login lockout; a copied home directory yields no usable private key; the udev/udev-access substrate is proven by real use.
     Cost: every remote must register both tokens; the work Mac needs a compatible OpenSSH/agent; losing both tokens requires re-registering every remote; resident-key slots are finite.
  2. **Device privilege authentication.** `sudo` and/or local login require the token factor.
     In practice: on `thiniel`, `sudo` asks for the token and a touch; the password remains a fallback only if the owner explicitly chooses one.
     Gain: protects the local privilege boundary against a stolen password or unattended session; the most direct use of the PAM U2F path in the supplied research.
     Cost: highest lockout risk; a backup token and a tested recovery login must exist before the factor becomes mandatory; no macOS coverage; the change touches PAM, which can make the device unadministrable if wrong.
  3. **Web-account authentication.** The tokens are enrolled as WebAuthn/passkey authenticators in browser accounts.
     In practice: GitHub and other accounts register the Swissbit and the Solo 2; signing in asks for a touch.
     Gain: phishing-resistant account security; the smallest device-side change (udev recognition) and no lockout of the device itself.
     Cost: most of the work is account-side enrollment outside this repository; it barely exercises the device configuration, so it is a weak first proof of the token substrate; account recovery policies are external.
  4. **Secret or disk unlock.** A token unlocks SOPS age material or a LUKS volume.
     In practice: `adlerkopf` unlocks its LUKS volume with a token touch at the console, or SOPS derives its age key from the token.
     Gain: secret material at rest is bound to carried hardware.
     Cost: does not apply to `thiniel` (OPAL SED); headless hosts need physical presence; a lost token can strand a disk; age support needs a compatible plugin and a recovery key, and the installed `age-plugin-yubikey` is PIV-only.
- Resolution: **Remote identity** because it extends the already verified `permitted-identity-selection` capability, carries no local login lockout, and proves the token-recognition/udev substrate through real use instead of a configuration-only claim. Rejected: device privilege authentication because it takes on the highest lockout risk before a backup token and recovery login are proven; web-account authentication because most of its work is account-side and it weakly exercises the device configuration; secret/disk unlock because it does not apply to `thiniel` and carries the highest recovery cost. The identity scope and client-device scope for this first stage remain open (Q3).

## Q3 — Which identities and client devices must the first remote-identity stage cover?

- Status: closed 2026-10-17 (user)
- Blocks: the first stage's success guarantee, the affected SSH identities, whether the work Mac is in scope, and how large the recovery surface is.
- Context: Q2 selected remote identity as the first stage. The repository currently holds a personal identity on `thiniel` (`~/.ssh/id_ed25519`) and personal plus company, client001, and client002 identities on `J6G6Y9JK7L`. `permitted-identity-selection` proves that a device reaches private repositories with the identity material it declares, and `adlerkopf` authorizes the `thiniel` key for server access. The first stage should prove the token path end to end without turning one device's migration into a fleet-wide identity cutover.
- Question: which identities and client devices must the first remote-identity stage cover?
- Options:
  1. **Personal identity on `thiniel` only.** The Linux laptop's personal identity moves into the token; the private-repository and server connections that already trust that identity are re-registered with the token-held public key. The work Mac keeps file keys; work identities are untouched.
     In practice: on `thiniel`, `git push` to a personal private repository requires a token touch; `ssh adlerkopf` likewise; the work Mac still uses `~/.ssh/id_ed25519_personal_2026-10-04`.
     Gain: the smallest end-to-end proof; one platform, one identity, one recovery surface; the existing VM verification path can be extended.
     Cost: the work Mac and the work identities remain file-based; the owner must carry the token to use the personal laptop's remotes.
  2. **Personal identity on both owner laptops.** The personal identity moves into the token on `thiniel` and `J6G6Y9JK7L`; work identities stay file-based.
     In practice: the work Mac's private-repository connection also prompts for the token; the company/client identities keep their files.
     Gain: one personal identity across both devices; proves macOS OpenSSH/agent compatibility early.
     Cost: extra macOS work (compatible OpenSSH/agent, launchd agent, no PAM/U2F); the work Mac is employer-managed, so installing a Nix OpenSSH may be constrained.
  3. **Personal and work identities on both laptops.** Every identity the owner uses on the devices that hold it moves into the tokens, including company and client material.
     In practice: the work Mac's company and client connections also prompt for a token; the owner needs separate resident credentials for each identity on each token.
     Gain: one consistent hardware-backed identity model across all owned work contexts.
     Cost: employer/client authorization changes; more resident-key slots and more recovery paths; a token loss affects paid work access, not just personal repositories.
  4. **All identities on all devices, including every server authorization.** The broadest cut: both laptops and every server account that trusts the owner's keys move to token-held identities.
     In practice: `adlerkopf`, `cupix001`, and the VMs also authorize token-held public keys, and the work Mac's work identities move too.
     Gain: the largest reduction in on-disk private keys.
     Cost: the largest recovery surface; every remote must register both tokens; a lost/broken token set blocks personal, work, and server access at once.
- Resolution: **Personal identity on `thiniel` only** because it is the smallest end-to-end proof: one platform, one identity, one recovery surface, and it extends the already verified `permitted-identity-selection` path. The work Mac's personal identity and all work identities remain file-based for this stage. Rejected: personal identity on both laptops because macOS OpenSSH/agent compatibility and the employer-managed work Mac add cost before the Linux path is proven; personal and work identities on both laptops because employer/client authorization and multiple resident credentials enlarge the recovery surface; all identities on all devices including every server authorization because a single token loss would then block personal, work, and server access at once. Server access that already trusts the `thiniel` personal identity is part of this stage; no server-side identity model changes beyond authorizing the token-held public key.

## Q4 — How should the two tokens be used: fixed primary and backup, or an equal pair?

- Status: closed 2026-10-17 (user)
- Blocks: which token is carried daily, how the backup is stored and exercised, and how many resident credentials each remote must trust.
- Context: Q3 scoped the first stage to the personal identity on `thiniel`. Both the Swissbit iShield Key and the Solo 2 are FIDO2/CTAP2.1 tokens; neither exports its private key. A backup therefore means a second, separately registered credential, not a copy of the first. The first stage must remain recoverable if the daily token is lost, forgotten, or broken, and the backup must be tested rather than assumed.
- Question: how should the two tokens be used in the first stage?
- Options:
  1. **Swissbit daily, Solo 2 backup.** The Swissbit stays on the owner's keyring; the Solo 2 is stored separately, e.g. at home in a safe. Both are registered on GitHub and on the servers that trust the personal identity.
     In practice: a daily `git push` uses the Swissbit; after losing it, the owner retrieves the Solo 2 and reaches the same remotes without re-enrolling anything.
     Gain: a clear break-glass separation; daily wear stays on one device; the backup's role is unambiguous.
     Cost: two resident credentials per remote; the backup must be kept current and exercised periodically; retrieving it may delay access.
  2. **Solo 2 daily, Swissbit backup.** The Solo 2 stays on the keyring; the Swissbit is the separately stored backup.
     In practice: the daily token is the open-firmware Solo 2, which the owner can update with `solo2-cli`; the Swissbit sits in reserve.
     Gain: the daily device is the one whose firmware the owner can inspect and update; the commercial key is the rugged reserve.
     Cost: the same two-credential enrollment; firmware updates add a maintenance step; the reserve is the device with less transparent firmware.
  3. **Equal pair, no fixed roles.** Both tokens are carried or either may be used for any connection; both are registered everywhere.
     In practice: the owner reaches for whichever token is at hand; both work identically.
     Gain: flexibility and immediate redundancy if one is unavailable; wear is distributed.
     Cost: both must be kept current and tested; there is no clear break-glass device or storage separation; a lost token is less distinguishable from the backup.
  4. **One token now, the second later.** Only one token is registered in this stage; the second is added in a later stage.
     In practice: the Swissbit is enrolled; the Solo 2 stays unused until a follow-up.
     Gain: less enrollment work and a faster first proof.
     Cost: no redundancy in the first stage; losing or breaking the enrolled token blocks access until account/server recovery; the stage cannot claim a tested recovery path.
- Resolution: **Swissbit daily, Solo 2 backup** because it gives the two tokens distinct roles: the Swissbit is carried and used daily, while the Solo 2 is stored separately as the break-glass credential and registered on the same remotes. Both are separately registered credentials; neither copies the other. Rejected: Solo 2 daily because its open firmware and `solo2-cli` update path are useful but do not outweigh a clear break-glass separation, and the owner's request names the Swissbit first; equal pair because it leaves no unambiguous reserve and both devices would need constant maintenance; one token now because the stage could not claim a tested recovery path.

## Q5 — What must the token-held identity protect against in the first stage?

- Status: closed 2026-10-17 (user)
- Blocks: whether the first stage requires only user presence or also a PIN/per-use verification; whether the existing file key may remain as a fallback; the minimum guarantee the stage can claim.
- Context: Q3 scoped the first stage to the personal identity on `thiniel`, and Q4 made the Swissbit the daily token and the Solo 2 the separately stored backup. A token-held SSH credential can stop several different attacks, but not all of them equally: it removes the usable private key from the device, and it can require a physical touch and a PIN for each use. The chosen threat decides which of those properties the stage must prove.
- Question: what must the first stage's token-held identity protect against?
- Options:
  1. **Stolen device or copied data.** A stolen laptop, copied home directory, or leaked backup must yield no usable SSH identity.
     In practice: an attacker with `thiniel`'s disk can read the key-handle file but cannot push to the private repository or log in to the servers; the token is elsewhere.
     Gain: directly addresses the main reason for a hardware key; low friction (one touch per authentication); the strongest fit for the existing `permitted-identity-selection` guarantee.
     Cost: does not stop malware that can ask the agent while the owner is present; does not protect an account whose password or session is stolen; a file-key fallback on the device would weaken the guarantee.
  2. **Malicious local process or unattended session.** A process must not be able to use the identity silently; every use requires the owner's physical confirmation.
     In practice: a compromised editor asks the agent to sign; the owner sees a touch prompt (and a PIN prompt if required) and denies it.
     Gain: protects against silent use of the identity on a running device.
     Cost: more prompts; a PIN or per-use verification adds friction and another recovery secret; not every SSH operation offers a meaningful prompt; user presence alone does not prove the owner understood the request.
  3. **Remote account or credential compromise.** A stolen password, session, or copied key file must not be enough to use the remote account.
     In practice: an attacker with the GitHub password still cannot push over SSH or add a new key without the token; the account's own 2FA and recovery policy also apply.
     Gain: covers account takeover in addition to device theft.
     Cost: SSH keys are the authentication factor, not a second factor for Git over SSH; full coverage needs WebAuthn enrollment (a later stage) and depends on GitHub's account settings; the first stage alone cannot claim it.
  4. **All of the above.** The token is the owner's general hardware-backed identity, and the first stage is the first layer of a broader posture.
     In practice: the first stage proves the stolen-device property; later stages add per-use verification and WebAuthn, each with its own guarantee.
     Gain: a coherent direction that matches Q1's "all, staged".
     Cost: the first stage must not claim the later properties; the threat model spans several stages, and each must be verified separately.
- Resolution: **All of the above, staged.** The overall threat model includes stolen-device/copied-data, malicious local process or unattended session, and remote account/credential compromise. The first stage proves only the stolen-device/copied-data property: a stolen disk or copied home directory yields no usable SSH identity. Per-use verification (PIN/`verify-required`) for the malicious-process threat and WebAuthn for remote-account compromise are later stages and must not be claimed by the first stage. Rejected: stolen-device only because it would leave the owner's stated broader posture unrecorded; malicious-local-process or remote-account compromise as the first stage's sole claim because those surfaces depend on later stages and would overstate what the SSH identity change delivers.

## Q6 — What is the recovery path when both tokens are lost or unavailable?

- Status: closed 2026-10-17 (user), but the chosen option conflicts with Q5; see Q7.
- Blocks: whether a non-token credential remains in existence, how the first stage proves recovery, and whether the file-based identity is removed from `thiniel`.
- Context: Q4 made the Solo 2 the separately stored backup, so losing one token is covered by the other. Losing both is not: neither token exports its private key, so recovery needs either a separately held credential or an external account/provider procedure. The first stage promises that a stolen or copied device yields no usable SSH identity, so a file key left on `thiniel` would weaken that promise. GitHub account recovery and the server providers' consoles exist but are outside this repository and are not currently exercised.
- Question: what recovery path must the first stage establish for the loss of both tokens?
- Options:
  1. **Offline recovery key.** A separate, passphrase-protected ed25519 key is generated, kept on encrypted offline media away from `thiniel`, and authorized on the same GitHub account and servers. It is never loaded into the daily agent.
     In practice: after losing both tokens, the owner retrieves the offline media, copies the key to a trusted machine, removes the old public keys from GitHub and the servers, and enrolls replacements.
     Gain: recovery independent of GitHub's or the providers' account procedures; preserves the stolen-device guarantee because no usable key remains on `thiniel`; the path can be tested by using the recovery key once.
     Cost: a long-lived private key exists; its media and passphrase must be protected, rotated, and tested; if the media and passphrase are lost together, recovery falls back to external account procedures.
  2. **Account and provider recovery only.** No additional SSH key exists; after both tokens are lost, the owner uses GitHub account recovery and the server providers' consoles to register new credentials.
     In practice: the owner signs in to GitHub with the account recovery method, deletes the token keys, and adds new ones; `adlerkopf` is reached through its console, `cupix001` through the netcup console.
     Gain: no long-lived file key; the smallest key inventory.
     Cost: recovery depends on external account policies and on physical/provider console access; not fully testable from the repository; if account recovery is unavailable, the access is lost.
  3. **Keep the existing file key on `thiniel` as a fallback.** The current `~/.ssh/id_ed25519` stays authorized and on disk; the token is preferred for daily use.
     In practice: the owner can always fall back to the file key, but a copied home directory also contains it.
     Gain: the easiest transition and rollback; no new recovery material.
     Cost: the first stage cannot claim that a stolen device yields no usable SSH identity; the file key remains the weakest link and must be removed in a later stage before the guarantee is true.
  4. **Third token as the recovery credential.** A third hardware token is purchased and stored separately; both existing tokens remain daily/backup.
     In practice: the third token is registered everywhere and stored with the offline recovery material.
     Gain: recovery uses the same mechanism as daily use; no long-lived file key.
     Cost: an additional purchase and a third credential on every remote; not available today, so the first stage would wait.
- Resolution: **Keep the existing file key on `thiniel` as a fallback** because the owner wants the transition and rollback to stay simple and does not want to manage separate recovery media now. Rejected: offline recovery key because it adds long-lived key material and offline media to protect and test; account/provider recovery only because it depends on external procedures and console access; third token because it requires a purchase the owner has not made. **Conflict:** this choice directly contradicts Q5's first-stage guarantee that a stolen device or copied home directory yields no usable SSH identity, because the file key stays on disk and authorized. Q7 must resolve which confirmed decision changes.

## Q7 — How should the Q5 guarantee and the Q6 recovery choice be reconciled?

- Status: closed 2026-10-17 (user)
- Blocks: the first stage's honest success guarantee, whether the file key stays on `thiniel`, and whether the first stage delivers the stolen-device property at all.
- Context: Q5 confirmed that the first stage proves a stolen device or copied home directory yields no usable SSH identity. Q6 then chose to keep the existing `~/.ssh/id_ed25519` on `thiniel` as a fallback, which means a copied home directory still contains a usable key. Both cannot hold. The owner must either revise the first stage's guarantee, protect the file key differently, or move the recovery material off the device.
- Question: which confirmed decision should change so the first stage has one consistent guarantee?
- Options:
  1. **Keep the file key; the first stage does not claim stolen-device resistance.** The first stage delivers token enrollment and daily token use, with the file key as fallback; the stolen-device guarantee moves to a later stage that removes the file key after a recovery mechanism exists.
     In practice: a copied `~/.ssh/id_ed25519` still authenticates; the token is preferred but not required; the topic's first stage is mainly substrate and migration.
     Gain: easiest migration and rollback; no new recovery material; no lockout.
     Cost: the main security benefit is deferred; the first stage does not improve the stolen-device posture and must say so.
  2. **Keep the file key but protect it with a strong passphrase and remove it from the agent.** The key stays on disk but is encrypted and not loaded; daily use is token-only. The guarantee becomes "no usable identity without the passphrase", not "no usable private key on the device".
     In practice: an attacker with the disk must crack the passphrase; the owner can still use the file key after entering it.
     Gain: a local recovery path without offline media; some protection if the passphrase is strong.
     Cost: not hardware-bound; offline brute-force remains possible; the passphrase is another recovery secret; the guarantee must be restated and cannot be called hardware-backed.
  3. **Move the file key off `thiniel` to encrypted offline media.** The current key (or a new recovery key) is removed from the device and stored away; it stays authorized on the remotes as the break-glass credential.
     In practice: `~/.ssh/id_ed25519` no longer exists on `thiniel`; the recovery copy is in the safe; daily use is token-only.
     Gain: preserves Q5's stolen-device guarantee and still gives an independent recovery path; no long-lived key on the device.
     Cost: a long-lived key exists offline; the media and passphrase must be protected, tested, and rotated; no local fallback on the laptop.
  4. **Remove the file key and rely on account/provider recovery only.** The stolen-device guarantee holds; recovery is external.
     In practice: after both tokens are lost, the owner uses GitHub account recovery and the provider consoles to enroll new credentials.
     Gain: strongest key hygiene, no long-lived file key, and the guarantee holds.
     Cost: recovery depends on external account policies and console access; not fully testable from the repository.
- Resolution: **Keep the file key; defer the guarantee.** The first stage delivers token enrollment and daily token use, with `~/.ssh/id_ed25519` on `thiniel` remaining authorized as the fallback. The first stage therefore does **not** claim that a stolen device or copied home directory yields no usable SSH identity; that guarantee moves to a later stage that removes the file key after a recovery mechanism exists. Rejected: passphrase-protecting the file key because it still leaves a private key on the device and changes the guarantee to a weaker passphrase claim; moving the file key off the device because the owner declined separate recovery media in Q6; removing it and relying on external recovery because the owner chose a local fallback. This resolution revises the first-stage portion of Q5; Q5's overall staged threat model stands.

## Q5 revision note

Q7 revised Q5's first-stage claim: the first stage no longer proves the stolen-device/copied-data property. It proves token enrollment, token-preferred daily use, and the file-key fallback. The stolen-device property remains part of the overall threat model and is deferred to a later stage that removes the file key after a recovery mechanism exists. Per-use verification and WebAuthn remain later stages.
