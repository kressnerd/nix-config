# Design Review: github-fetch-credential

## Method

Final pass, after implementation. Six rounds of review ran over the planning
layer; this one verified the last three edits, re-checked the records they cite,
looked for newly introduced inconsistencies and re-ran the gates.

```
python3 scripts/givn-spec-trace.py         → 29 scenario(s), 0 finding(s); exit 0
givn lint --change github-fetch-credential → clean (plus the accepted shape advisory)
findmnt -no SOURCE,FSTYPE /persist         → /dev/mapper/root_vg-root[/persist] btrfs
nix eval --raw .#nixosConfigurations.nixos-vm-minimal.config.system.build.toplevel.drvPath → exit 0
```

## Final edits — confirmed

1. **`design.md` (the `hosts/common/global` change note, lines 273-281).** The
   note no longer attributes placement to chapter 11: it states that
   `docs/ARCHITECTURE.md` is treated as historical for its stale host/feature
   inventory ("R-004/TD-005 records drift about hosts and files that do not
   exist, not module placement"), that the arc42 baseline is the corrected
   account, that the `hosts/common/optional/` pattern itself stays in use
   (thiniel imports two of its modules), that this change deliberately places one
   option pair in the shared base for the aggregated-assertion reason, and that
   chapter 8's "Typed option modules as the host/module contract" is the durable
   account, now listing this pair. Confirmed against the records: R-004
   (`docs/arc42/11-risks-and-technical-debt.md:14`) and TD-005 (`:49`) enumerate a
   host/feature inventory, and `docs/arc42/01-introduction-and-goals.md:107`
   records the same "known stale prose (not authoritative): the host inventory";
   `hosts/thiniel/default.nix:13-14` imports `optional/networkmanager.nix` and
   `optional/virtualisation.nix` (chapter 5's table also records `optional/docker.nix`
   as imported by no host).
2. **`docs/arc42/08-crosscutting-concepts.md:83-87`.** The present-pairs list now
   reads `modules/home-manager/{ssh,persistence}`, `modules/nixos/persistence`,
   `modules/nixos/github-fetch-credential` (imported through the shared base,
   guarding its definitions with `lib.optionalAttrs (options ? sops)`), which
   matches the implemented module and the section's own contract statement
   (disabled defaults, no silently wrong default).
3. **`givn/changes/github-fetch-credential/arc42.md:35-39`.** The chapter-8 entry
   of "Chapter updates performed" records the present-pairs addition with its
   shared-base import and the `options ? sops` guard — matching what chapter 8
   now says.

No other statement in the change or the chapters misattributes the placement
rule, and no new inconsistency was introduced.

## Findings — final status

| # | Pass | Was | Finding | Status |
|---|---|---|---|---|
| F-001 | 1 | Blocking | A committed plaintext age key would be refused by the repository's own gitleaks scan | Resolved — build-time fixture; no allowlist; TD-016 |
| F-002 | 1 | Blocking | The rendered fragment depended on the owner's user session | Resolved for Linux (system activation); the Mac's residual is R-029 |
| F-003 | 1 | Blocking | `design.md`'s arc42 impact section contradicted `arc42.md` | Resolved |
| F-004 | 1 | Blocking | Two canonical destinations for the non-qualified ADR candidate | Resolved — one destination |
| F-005 | 1 | Advisory | Stale proposal quotation in the Decisions ledger | Resolved |
| F-006 | 1 | Advisory | `@check:integration-github-fetch-credential` did not resolve | Resolved — wired; spec-trace exits 0 |
| F-007 | 1 | Advisory | An unasserted "reported" behaviour in the use-case rule | Resolved |
| F-008 | 1 | Advisory | `givn lint` shape advisory on the two per-host scenarios | Accepted and recorded in `design.md` |
| F-009 | 1 | Advisory | The home-manager-side mechanism was not named | Resolved |
| N-001 | 2 | Blocking | The Mac's secret/template were declared in the darwin host module | Resolved — home profile declares them; host module only the activation script |
| N-002 | 2 | Blocking | No import site gave adlerkopf the option its exclusion assertion reads | Resolved — `hosts/common/global`, now guarded |
| N-003 | 2 | Advisory | A stale "committed test fixture" sentence in chapter 10 | Resolved |
| N-004 | 2 | Advisory | The check was still counted as Home-Manager-loading | Resolved — chapters 5 and `arc42.md` agree on three |
| N-005 | 2 | Advisory | The store-path absence assertion was unsatisfiable for the fixture's own value | Resolved — scoped in the design and the test |
| O-001 | 3 | Blocking | The "Unchanged" list excluded `hosts/common/**` while the "Changed" list added it | Resolved |
| O-002 | 3 | Advisory | `arc42.md` said "fourth Home-Manager-loading check" | Resolved — "third" |
| D-001 | 5 | Advisory | The design did not record that the production laptop is unaffected by the initrd ordering | Resolved — verified (`/persist` subvolume, `neededForBoot = true`, key path) |
| D-002 | 5 | Advisory | The fixture's key nesting was only implied | Resolved — `github:` → `access-token:` stated, matching module and test |
| D-003 | 5 | Advisory | The conditional pair sits in the shared base rather than the recorded optional pattern | Resolved — rationale stated and verified; pattern recorded as still in use |
| B-1 | 6 | Blocking | The note attributed the placement rule's staleness to R-004/TD-005, and the chapter it called "the corrected account" omitted the new pair | Resolved — see the three confirmed edits above |

## Branch dispositions (final)

| Branch | Result |
|---|---|
| Scope | No finding. The spec covers exactly the proposal; out-of-scope items are asserted by no step. |
| Tech choices | No finding. The implemented module, the fixture derivation, the initrd tmpfiles ordering, the include mechanism and the `options ? sops` guard are all verified against the pinned sources and the flake; the production shape is unaffected by the fixture's ordering constraint. |
| Missing scenarios | No finding. The use-case rule's failure wording is fixed; the store/process-environment prohibitions are asserted by the `@e2e` target, which may assert more than the scenario states. |
| Testability | No finding. Scenarios 1 and 3 fail first on the absent option and then pass; scenario 2 fails on named assertions written against existing options; the `@e2e` target exists, boots and passes, with its RED and GREEN recorded in `tasks.md`. |
| Verification binding completeness | No finding. Four scenarios, exactly one binding tag each; `@e2e` bound to a `@check:integration-*`; `verify.e2e_command` differs from `verify.command`; every name resolves (`givn-spec-trace` exit 0). |
| Deployment & rollback | No finding. Operator step, apply commands, on-host verification (both platforms) and rollback are recorded for a secret-wiring change. |
| Persona disposition | No finding. `owner--operator` relevant; `family--application-user` unaffected; no Persona invented, promoted, or used as a Gherkin actor. |
| ADR qualification | No finding. One candidate, `NOT_QUALIFIED`, one canonical destination, evidence matching the design's alternatives; no MADR required or missing. |
| Risk | No finding. R-026–R-029 and TD-016 record the residual risks with mitigations; the initrd-ordering dependency is test-local and explained. |
| arc42 chapters | No finding. Independent twelve-row walk gives Yes = 05, 06, 08, 09, 10, 11, 12 and No = 01, 02, 03, 04, 07, matching `arc42.md`; all chapters exist with real content and no ASCII-art diagrams; the edited chapters now match the design, including the option-pair inventory and the placement note. |
| Ubiquitous language | No finding. `docs/arc42/12-glossary.md` carries *GitHub fetch credential* with its contrast pair; no term is reused inconsistently. |
| Gates | `givn lint` clean (only the accepted F-008 advisory); `scripts/givn-spec-trace.py` reports 29 scenarios, 0 findings, exit 0. The pending Scenario 4 `givn commit` is the tasks step's business. |

## Sign-off

Every finding from all six rounds is resolved or explicitly accepted: the four
round-1 blockers, the two round-2 blockers, the round-3 blocker, the round-6
blocker and all advisories. The implementation and its documentation now agree
with each other and with the durable chapters, and both gates pass.

DESIGN-REVIEW: PASS
