# arc42 Documentation Update: security-key-remote-identity

## Impact assessment

| # | Chapter | Affected? | Reason | Summary of change (if Yes) |
|---|---|---|---|---|
| 1 | 01 introduction-and-goals | No | No goal or quality goal changes; the existing access-security goal is met by one more credential path. | — |
| 2 | 02 architecture-constraints | No | No new technical, organisational or regulatory constraint; the existing nixpkgs 26.05 and Home Manager/NixOS structure are used. | — |
| 3 | 03 context-and-scope | **Yes** | The technical context gains a security-key SSH interface from `thiniel` to GitHub and the declared hosts; the external partners are unchanged. | Added the security-key interface row and a scope note. |
| 4 | 04 solution-strategy | No | The strategy remains host declarations feeding shared Home Manager features; this change applies it to SSH identities. | — |
| 5 | 05 building-block-view | **Yes** | New `lib/security-key.nix`, extended SSH options/feature, and two VM integration checks; no deploy layer is added. | Updated the building-block table, the `home-manager/ssh` options row, the SSH feature rows, and the test-layer description. |
| 6 | 06 runtime-view | **Yes** | New runtime flows for security-key authentication, the named fallback, and lost-key revocation. | Added two Mermaid sequence scenarios and their verification notes. |
| 7 | 07 deployment-view | No | No host or topology change; `thiniel` remains the same device and the declared hosts keep their roles. | — |
| 8 | 08 crosscutting-concepts | **Yes** | New cross-cutting concept: security-key identity with non-resident handles and a named file-key fallback. | Extended the identity-declaration concept and added the security-key identity section. |
| 9 | 09 architecture-decisions | No | No ADR. The non-resident-handle decision has alternatives and impact, but its complete rationale is owned by `design.md` D2/Q8 and the glossary; `lower_level_artifact` fails the qualification gate. Existing ADRs do not cover SSH security-key handles. | No chapter-09 edit. |
| 10 | 10 quality-requirements | **Yes** | New access-security scenario for token-present/absent/lost, with VM e2e and manual real-token/backup gates. | Added QS-018; QS-010 remains the no-deploy-target statement. |
| 11 | 11 risks-and-technical-debt | **Yes** | Handle-file loss, token-plus-handle theft, the CI gap for physical gates, and the unverified Swissbit Ed25519 assumption are new risks. | Added R-031–R-034; TD-005/TD-007 keep the deploy layer absent. |
| 12 | 12 glossary | No | The eleven security-key terms and the reused identity terms were promoted before this change; no new term is introduced. | — |

## Notes

- Chapters 03, 05, 06, 08, 10 and 11 were updated in place. Chapter 12 was already current; chapters 01, 02, 04, 07 and 09 need no edit.
- The repeatable proof is the VM e2e with a virtual FIDO2 authenticator (P-256). The real-token, backup-token, and backup-restore gates are operator-run on `thiniel` and recorded in `backup-drill.md`; CI cannot exercise the physical path.
- No new external partner, host, service, secret, or deployment topology is introduced.

```text
ADR action: CANONICAL_ARTIFACT
ADR target: givn/changes/security-key-remote-identity/design.md

qualification: NOT_QUALIFIED
alternatives: PASS — non-resident/no verify-required vs resident vs verify-required
architectural_impact: PASS — fixes the credential/handle boundary for the personal identity
durable_consequence: PASS — later change would require re-enrollment and remote authorization changes
lower_level_artifact: FAIL — the complete rationale is owned by design.md D2/Q8; no ADR
existing_adr_check: PASS — no existing ADR covers SSH security-key handles
must_be_shared: SUPPORTING
routing: CANONICAL_ARTIFACT
canonical_artifact: givn/changes/security-key-remote-identity/design.md
target_adr: none
replacement_adr: none
```

## Status

STATUS: DONE
