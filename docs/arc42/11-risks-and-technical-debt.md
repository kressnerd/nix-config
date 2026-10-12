# 11. Risks and Technical Debt

<!-- Known risks and technical debt that may affect the architecture or project.
     For each item: describe it, its potential impact, and any mitigation. -->

## Risks

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R-001 | A declared personal identity file is absent on the device (stale path after a key rotation, or key removed) | Medium | Medium | The declaration is proven on the device after activation: `ssh -G <connection>` must name an existing key file, and a private-repository `git fetch` must succeed. Failure is fail-closed: no key is presented and access is denied, never broadened. |
| R-002 | A host declares a work identity's secret material without holding that identity's key file, so it renders a connection entry it cannot use | Low | Low | The same declaration gates both the connection entry and the workspace identity profile, so the two cannot drift apart; a missing key still fails closed. |
| R-003 | A second work device inherits the MacBook's work identity surface if it declares the same secret material with different key files | Low | Medium | Accepted for now: no second work device exists. Recorded as technical debt TD-001 with the parameterization that removes it. |

## Technical debt

| ID | Item | Impact | Plan to address |
|---|---|---|---|
| TD-001 | The three work identity key file names remain literals inside the SSH feature, gated by the declared secret material rather than declared per host the way the personal identity is | A second work device would render the MacBook's key paths and fail closed | Parameterize the work identity key paths in `myHome.ssh` when a second host needs them |
