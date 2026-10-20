# Tasks: security-key-remote-identity

Status: ready for implementation

Every scenario below is one RED/GREEN/REFACTOR/COMMIT loop against its bound native target. Do not remove `@wip` from any scenario before the setup task has wired and proved the target. `@e2e` tags are immutable.

## Setup — wire and prove the verification targets

Apply the domain constraints from the use case and seed: one key from `thiniel` represents the user on `thiniel`, `adlerkopf`, `nixos-vm-minimal`, and GitHub personal; handles are non-resident; daily token then backup; the file-backed identity is only the named fallback; no stolen-laptop claim; a lost key is revoked at every declared remote; failed revocation is not success.

- [ ] Run `python3 scripts/givn-spec-trace.py`. Before the targets exist it fails on the new check names; paste the failure. It must exit 0 after the wiring below.
  - Evidence: `TBD`

- [ ] Wire `tests/unit/security-key-identity.nix` as flake check `unit-security-key-identity` (direct import in `flake.nix`, not the `unit-helpers` aggregate).

- [ ] Wire `security-key-fleet-authorizations` in `flake.nix`; it evaluates `self.nixosConfigurations` and filters `services.openssh.enable`.

- [ ] Wire `tests/assertions/thiniel-security-key-invariants.nix` in `tests/assertions/default.nix`; guard the body with `lib.mkIf (config.networking.hostName == "thiniel")`.

- [ ] Wire `tests/integration/security-key-authentication-test.nix` and `...-revocation-test.nix` in `tests/integration/default.nix`; define both checks only for `x86_64-linux`.

- [ ] Add `pkgs/fidorium/default.nix` with `tpm2-tss`/`libtss2-esys`, `pinentry`, `/dev/uhid`, and `virtualisation.tpm.enable` in the VM tests.

- [ ] Add `tokenIdentityFiles = [ ]` to the raw mocks in `tests/unit/hm-cli-modules-test.nix` (or read the option with `or []`).

- [ ] Add one deliberately failing target (a wrong literal or unmet `expected`), run the targeted command, and paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] Confirm `verify.command` and `verify.e2e_command` in `givn/commands.yaml` are not identical; record `@e2e` count (7) and total scenario count (21).
  - Evidence: `TBD`

- [ ] Confirm the Linux/KVM builder boots a trivial `runNixOSTest` smoke target.
  - Evidence: `TBD`


## 1. The device declares support for both security keys and the fallback

- Binding: `@host:thiniel`
- Target: `tests/assertions/thiniel-security-key-invariants.nix`
- Targeted command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
- Domain constraints: One key from `thiniel` represents the user on `thiniel`, `adlerkopf`, `nixos-vm-minimal`, and GitHub personal; handles are non-resident; the file-backed identity is only the named fallback; no stolen-laptop claim.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(security-key-enrollment-and-authorization): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 2. Every declared host authorizes the personal token public identities

- Binding: `@check:security-key-fleet-authorizations`
- Target: flake check `security-key-fleet-authorizations` in `flake.nix`
- Targeted command: `nix build .#checks.x86_64-linux.security-key-fleet-authorizations`
- Domain constraints: One key from `thiniel` represents the user on `thiniel`, `adlerkopf`, `nixos-vm-minimal`, and GitHub personal; handles are non-resident; the file-backed identity is only the named fallback; no stolen-laptop claim.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(security-key-enrollment-and-authorization): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 3. The identity declaration records both token credentials and the fallback order

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: One key from `thiniel` represents the user on `thiniel`, `adlerkopf`, `nixos-vm-minimal`, and GitHub personal; handles are non-resident; the file-backed identity is only the named fallback; no stolen-laptop claim.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(security-key-enrollment-and-authorization): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 4. Normal connections use the daily token and not the file-backed identity

- Binding: `@host:thiniel`
- Target: `tests/assertions/thiniel-security-key-invariants.nix`
- Targeted command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(token-preferred-remote-authentication): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 5. The daily token is selected when it is available

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(token-preferred-remote-authentication): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 6. An absent daily token uses the backup token

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(token-preferred-remote-authentication): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 7. Both tokens unavailable require the named fallback

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(token-preferred-remote-authentication): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 8. A rejected daily credential may use the backup token

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(token-preferred-remote-authentication): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 9. The identity declaration names the public identities and the remotes that authorize them

- Binding: `@host:thiniel`
- Target: `tests/assertions/thiniel-security-key-invariants.nix`
- Targeted command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
- Domain constraints: One key from `thiniel` represents the user on `thiniel`, `adlerkopf`, `nixos-vm-minimal`, and GitHub personal; handles are non-resident; the file-backed identity is only the named fallback; no stolen-laptop claim.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(lost-security-key-revocation): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 10. A lost daily key is revoked at every remote while the backup is retained

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Revoke every declared remote that authorized the lost public identity; a failed, unreachable, or unverified revocation is not success; the remaining credential and the file-backed identity stay available.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(lost-security-key-revocation): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 11. Both lost keys are revoked and the file-backed identity remains

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Revoke every declared remote that authorized the lost public identity; a failed, unreachable, or unverified revocation is not success; the remaining credential and the file-backed identity stay available.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(lost-security-key-revocation): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 12. A failed revocation is not reported as removed

- Binding: `@check:unit-security-key-identity`
- Target: `tests/unit/security-key-identity.nix`
- Targeted command: `nix build .#checks.x86_64-linux.unit-security-key-identity`
- Domain constraints: Preserve the use-case contract: token-preferred, no file-key substitution, non-resident handles, no stolen-laptop claim.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(lost-security-key-revocation): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 13. A lost public identity is removed from the declaration and the remaining identity stays authorized

- Binding: `@host:thiniel`
- Target: `tests/assertions/thiniel-security-key-invariants.nix`
- Targeted command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
- Domain constraints: Revoke every declared remote that authorized the lost public identity; a failed, unreachable, or unverified revocation is not success; the remaining credential and the file-backed identity stay available.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(lost-security-key-revocation): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 14. The personal device reaches private repositories with the identity it holds

- Binding: `@host:thiniel`
- Target: `tests/assertions/thiniel-invariants.nix (updated)`
- Targeted command: `nix eval --raw .#nixosConfigurations.thiniel.config.system.build.toplevel.drvPath`
- Domain constraints: One key from `thiniel` represents the user on `thiniel`, `adlerkopf`, `nixos-vm-minimal`, and GitHub personal; handles are non-resident; the file-backed identity is only the named fallback; no stolen-laptop claim.

- [ ] RED — remove `@wip` from this scenario only; extend the target to assert the Then; run the targeted command; paste a non-zero exit for the expected reason. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the minimum configuration change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up without behaviour change; run the targeted command; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "feat(permitted-identity-selection): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 15. A recognized security key is not authorized until its public identity is granted

- Binding: `@check:integration-security-key-authentication`
- Target: `tests/integration/security-key-authentication-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-authentication` (or `verify.e2e_command`)
- Domain constraints: Preserve the use-case contract: token-preferred, no file-key substitution, non-resident handles, no stolen-laptop claim.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 16. The daily key authenticates at the designated test remote after enrollment and authorization

- Binding: `@check:integration-security-key-authentication`
- Target: `tests/integration/security-key-authentication-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-authentication` (or `verify.e2e_command`)
- Domain constraints: Preserve the use-case contract: token-preferred, no file-key substitution, non-resident handles, no stolen-laptop claim.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 17. A token connection succeeds only with a touch

- Binding: `@check:integration-security-key-authentication`
- Target: `tests/integration/security-key-authentication-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-authentication` (or `verify.e2e_command`)
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 18. A token connection without a touch is rejected

- Binding: `@check:integration-security-key-authentication`
- Target: `tests/integration/security-key-authentication-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-authentication` (or `verify.e2e_command`)
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 19. A token without its handle file does not authenticate

- Binding: `@check:integration-security-key-authentication`
- Target: `tests/integration/security-key-authentication-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-authentication` (or `verify.e2e_command`)
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 20. A rejected daily credential is not retried with the file-backed identity

- Binding: `@check:integration-security-key-authentication`
- Target: `tests/integration/security-key-authentication-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-authentication` (or `verify.e2e_command`)
- Domain constraints: Daily token first, backup token when the daily is absent or rejected; the file-backed identity is only through the named fallback; touch only; no `verify-required`.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## 21. A lost public identity is revoked at the designated test remote and no longer authenticates

- Binding: `@check:integration-security-key-revocation`
- Target: `tests/integration/security-key-revocation-test.nix`
- Targeted command: `nix build .#checks.x86_64-linux.integration-security-key-revocation` (or `verify.e2e_command`)
- Domain constraints: Revoke every declared remote that authorized the lost public identity; a failed, unreachable, or unverified revocation is not success; the remaining credential and the file-backed identity stay available.

- [ ] RED — remove `@wip`; add/extend the VM assertion; run the targeted integration build or `verify.e2e_command`; paste a non-zero exit. Exit 0 is a hard stop.
  - Evidence: `TBD`

- [ ] GREEN — implement the VM infrastructure (fidorium, TPM, uhid, pinentry approve/deny, sshd, test remote); run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] REFACTOR — clean up; run the targeted build; paste exit 0.
  - Evidence: `TBD`

- [ ] COMMIT — `givn commit -m "test(e2e): <release note>"` with the scenario title in the body.
  - Commit: `TBD`


## Manual gates before archive

- [ ] `backup-drill.md`: encrypted backup + restore + backup-token authentication under 15 minutes; paste the completed record reference.
- [ ] `revocation-drill.md`: GitHub, `adlerkopf`, `nixos-vm-minimal`, `thiniel` each report the lost test identity removed or an accepted failure.
- [ ] `verify.command` and `verify.e2e_command` both exit 0 on the Linux/KVM builder; paste both results.

