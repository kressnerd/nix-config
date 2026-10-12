# Preserved from local branches (2026-10-12)

Before the local work branches were removed, their content was compared against
`main` and everything that `main` lacked was either brought over or explicitly
judged superseded. This file records that comparison so the decision is
auditable.

Branches examined: `worktree/roo-f8e9n`, `worktree/roo-geph2`,
`backup-before-squash`, `backup-f8`, `backup-ge`, `refactor-dir`, `origin/wip/luks`.

## Brought into `main`

Every file below was absent from `main`. Each document carries a provenance line
naming its source branch; the hosting-provider resolver addresses in
`EDGE-INGRESS-GATEWAY.md` were replaced with public resolvers before it was
recorded.

| Path | Source branch |
|---|---|
| `README-CONTAINERS.md` | `origin/wip/luks` |
| `docs/DECLARATIVE-SSH-KEY-MANAGEMENT.md` | `origin/wip/luks` |
| `docs/DEPLOYMENT-REMOTE-LUKS.md` | `origin/wip/luks` |
| `docs/INITRD-NETWORK-TROUBLESHOOTING.md` | `origin/wip/luks` |
| `docs/LUKS-LOOP-TROUBLESHOOTING.md` | `origin/wip/luks` |
| `docs/REMOTE-LUKS-UNLOCK.md` | `origin/wip/luks` |
| `docs/DOOM-EMACS-INTEGRATION-STRATEGY.md` | `origin/wip/luks` |
| `docs/DOOM-EMACS-INTEGRATION-SUMMARY.md` | `origin/wip/luks` |
| `docs/DOOM-EMACS-NIX-ANALYSIS.md` | `origin/wip/luks` |
| `docs/DOOM-EMACS-PACKAGE-MANAGEMENT.md` | `origin/wip/luks` |
| `docs/EMACS-SETUP.md` | `origin/wip/luks` |
| `docs/THINIEL-INTEGRATION.md` | `origin/wip/luks` |
| `docs/TODO.md` | `origin/wip/luks` |
| `docs/EDGE-INGRESS-GATEWAY.md` | `refactor-dir` |
| `docs/CUPIX001-DEPLOYMENT.md` | `refactor-dir` |
| `docs/plans/nix-skills-design-plan.md` | `refactor-dir` |
| `scripts/generate-initrd-keys.sh` | `origin/wip/luks` |

`scripts/generate-initrd-keys.sh` is the companion tooling of the three
remote-LUKS documents, which reference it by name.

Two of the brought documents close dangling references that `main` already had:
`docs/VM-TESTING.md`, `docs/VM-TESTING-GUIDE.md` and `CLAUDE.md` link
`docs/CUPIX001-DEPLOYMENT.md`, and `CLAUDE.md` links
`docs/EDGE-INGRESS-GATEWAY.md`. That also removes two entries from the
documentation-drift risk recorded as R-004 in
[arc42 chapter 11](arc42/11-risks-and-technical-debt.md).

One adlerkopf change was preserved as code rather than documentation: the
missing half of `worktree/roo-f8e9n`'s `f8dd195` — removing the stale
`device = "/dev/disk/by-partlabel/cryptroot"` line from
`hosts/adlerkopf/tpm2.nix`. `main` already carried the lanzaboote `v1.0.0` half
of that commit; the missing half was the cause of R-017 and is now fixed.

## Not brought — superseded or private

| Path | Branches | Reason |
|---|---|---|
| `hosts/adlerkopf/private.nix`, `hosts/cupix001/private.nix` | `worktree/roo-*` | The superseded local-file mechanism, and operational values. Replaced by the overridable `private` flake input. |
| `hosts/*/private.nix.example` | `worktree/roo-*`, `backup-*` | The same superseded mechanism; the schema stays documented in the public `options.nix` files. |
| `private.md` | `worktree/roo-*` | Operational notes, recorded outside the repository. |
| `hosts/*/secrets.yaml` (branch revisions) | `refactor-dir`, `origin/wip/luks`, `worktree/roo-*` | Older revisions of files `main` already carries in their current, encrypted form. |
| `modules/nixos/systemd-sleep-settings.nix` | `worktree/roo-*`, `backup-*` | Superseded: it translated `systemd.sleep.settings.Sleep` into `extraConfig` for nixpkgs 25.11; nixpkgs 26.05 provides the structured option, which `hosts/thiniel/default.nix` uses directly. |
| `home/dan/features/linux/impermanence.nix` | `backup-*`, `refactor-dir`, `origin/wip/luks` | Superseded by `modules/home-manager/persistence`. Referenced only by historical plan text. |
| `home/dan/doom.d/{config,init,packages}.el` | `origin/wip/luks` | Moved to `home/dan/dotfiles/doom.d/` by the directory refactor. |
| `home/dan/global/linux.nix` | `origin/wip/luks` | Superseded by `home/dan/global/default.nix`. |
| `home/dan/features/productivity/firefox-linux.nix` | `origin/wip/luks` | Superseded by `features/productivity/browser.nix` and the `firefox-*` profiles. |
| `home/dan/features/productivity/tools.nix` | `origin/wip/luks` | Superseded by `features/productivity/keepassxc.nix`. |
| `hosts/thiniel-vm/{default,disko,hardware,home}.nix`, `hosts/thiniel-vm/secrets.yaml`, `home/dan/thiniel-vm.nix` | `origin/wip/luks` | A temporary host removed by the directory refactor. |
| `hosts/J6G6Y9JK7L/home.nix`, `hosts/nixos-vm-minimal/home.nix` | `origin/wip/luks` | Old module locations, since moved. |
| `modules/{home-manager,nixos}/.gitkeep` | `backup-*`, `refactor-dir` | Empty placeholders. |

## Safety net

Before the branches were removed, every ref was captured in a bundle outside the
repository (it contains the private data the branches carried, so it must never
be pushed):

```bash
git bundle create ~/dev/PRIVATE/nix-config-allrefs-2026-10-12.bundle --all
```

A second, complete safety net was taken for the history rewrite:
`~/dev/PRIVATE/nix-config-mirror-20261012.git` (`git clone --mirror`), plus a
refreshed `~/dev/PRIVATE/nix-config-allrefs-20261012.bundle`. Restore from the
bundle with `git clone ~/dev/PRIVATE/nix-config-allrefs-2026-10-12.bundle <dir>`
or `git fetch <bundle> <ref>`. Keep it until the private-data remediation's
history rewrite has completed and its own mirror backup is no longer needed.

## Removal

Once the content above was in `main` and the bundle was verified, the branches
were removed on 2026-10-12:

- the two linked worktrees (`/home/dan/.roo/worktrees/nix-config-{f8e9n,geph2}`)
  and every local branch (`backup-before-squash`, `backup-f8`, `backup-ge`,
  `refactor-dir`, `worktree/roo-f8e9n`, `worktree/roo-geph2`);
- the two published branches on `origin` (`refactor-dir`, `wip/luks`), which
  also removes their pre-remediation content from the public remote before the
  history rewrite.

`main` is the only branch left, locally and on `origin`.

The stash (`refs/stash`, holding the last real `hosts/*/private.nix` values) is
untouched and is not pushed; it is captured in the bundle.
