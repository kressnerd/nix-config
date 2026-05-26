# One Light Theme Migration — Implementation Plan

**Status**: DRAFT — Pending Approval
**Owner**: Architect → Orchestrator → Code
**Affected hosts**: `thiniel` (NixOS), `J6G6Y9JK7L` (nix-darwin/macOS)
**Theme transition**: Catppuccin Latte → One Light (base16)

---

## 1. Business Context

The system-wide theme is currently **Catppuccin Latte**, delivered via [Stylix](https://github.com/nix-community/stylix) with `autoEnable = false`. While Catppuccin Latte is visually appealing, its measured WCAG contrast ratio is ~7.1:1.

**One Light** (Atom-derived base16 scheme) reaches ~10.9:1 — a **~54 % contrast improvement** while keeping the same warm-neutral light aesthetic. Migrating to One Light improves readability across every Stylix-themed surface (kitty, waybar, fuzzel, mako, hyprlock, GTK, Qt, Hyprland borders, fish, starship, bat, etc.) at zero structural cost: the delivery mechanism (Stylix base16 + selective opt-in) stays unchanged. Only the **scheme content** and the four hard-coded Catppuccin-only artefacts (vim plugin, Emacs theme, cursor package, wallpaper) need migration.

## 2. Acceptance Criteria

1. `stylix.base16Scheme` on **both** hosts uses the One Light palette (the 16 hex values listed in §3.1).
2. `stylix.polarity = "light"` is preserved on both hosts.
3. `stylix.autoEnable = false` is preserved on both hosts.
4. All existing `stylix.targets.<app>.enable = true` opt-ins remain enabled and unchanged.
5. Font configuration ([`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix:478) and [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:120)) is unchanged.
6. [`home/dan/features/cli/vim.nix`](../../home/dan/features/cli/vim.nix:1) is Stylix-managed (`stylix.targets.vim.enable = true`); no `catppuccin-vim` plugin, no `colorscheme catppuccin_latte`, no manual `background`/`termguicolors`.
7. [`home/dan/features/productivity/emacs.nix`](../../home/dan/features/productivity/emacs.nix:1) no longer declares `catppuccin-theme` and no longer evaluates `(load-theme 'catppuccin t)`.
8. On `thiniel`, `stylix.image` is a One-Light-compatible wallpaper source that is **not** `pkgs.nixos-artwork.wallpapers.catppuccin-latte.*`.
9. On `thiniel`, `stylix.cursor.package` is **not** `pkgs.catppuccin-cursors.latteBlue` (a neutral cursor theme is used; default chosen: `pkgs.bibata-cursors`).
10. On `J6G6Y9JK7L`, the runtime-generated solid-colour wallpaper uses `#fafafa` (One Light `base00`), not `#eff1f5`.
11. Unit tests in [`tests/unit/hm-cli-modules-test.nix`](../../tests/unit/hm-cli-modules-test.nix:1) no longer reference `catppuccin_latte` or `catppuccin-vim`; new tests assert vim is Stylix-managed.
12. Repo-wide check `grep -rn 'catppuccin\|catppuccin_latte\|catppuccin-vim\|catppuccin-cursors\|catppuccin-theme\|eff1f5\|4c4f69\|d20f39\|7287fd' hosts/ home/ tests/` returns zero matches for **Nix-affected paths** (Doom-managed `home/dan/dotfiles/` may retain references — see §7).
13. `nix flake check` PASSES.
14. `nixos-rebuild build --flake .#thiniel` PASSES.
15. `darwin-rebuild build --flake .#J6G6Y9JK7L` PASSES (or `nix build .#darwinConfigurations.J6G6Y9JK7L.system` cross-eval where applicable).
16. After `switch`, manual visual checks (§5.4) confirm One Light is active in all primary surfaces.

## 3. Technical Analysis

### 3.1 One Light Base16 Palette (Single Source of Truth)

| Slot   | Hex      | Role                  |
|--------|----------|-----------------------|
| base00 | `fafafa` | Background            |
| base01 | `f0f0f1` | Alt background        |
| base02 | `e5e5e6` | Selection bg          |
| base03 | `a0a1a7` | Comments              |
| base04 | `696c77` | Dark decoration       |
| base05 | `383a42` | Text (dark gray)      |
| base06 | `202227` | Light fg              |
| base07 | `090a0b` | Near-black            |
| base08 | `ca1243` | Red                   |
| base09 | `d75f00` | Orange                |
| base0A | `c18401` | Yellow                |
| base0B | `50a14f` | Green                 |
| base0C | `0184bc` | Cyan                  |
| base0D | `4078f2` | Blue                  |
| base0E | `a626a4` | Purple                |
| base0F | `986801` | Brown                 |

Scheme metadata: `scheme = "One Light"`, `author = "Daniel Pfeifer (http://github.com/purpleKarrot)"` (matches upstream `base16-schemes/one-light.yaml`).

### 3.2 Delivery Strategy per Host

#### `thiniel` (NixOS, [`hosts/thiniel/default.nix:451`](../../hosts/thiniel/default.nix:451))

Currently uses an **inline base16 attrset** (no IFD) so that cross-system eval from macOS works without `--no-build`. Strategy: keep the **inline attrset pattern**, replace the 16 hex values + scheme metadata. Do NOT switch to `"${pkgs.base16-schemes}/share/themes/one-light.yaml"` because that would re-introduce IFD and break the macOS evaluator's ability to evaluate `thiniel` without building.

#### `J6G6Y9JK7L` (nix-darwin, [`hosts/J6G6Y9JK7L/default.nix:112`](../../hosts/J6G6Y9JK7L/default.nix:112))

Currently uses the **file path form** `"${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml"`. The macOS host evaluates only itself (no cross-host eval pressure), so the file path form is safe. Strategy: change filename suffix `catppuccin-latte.yaml` → `one-light.yaml`. The package `pkgs.base16-schemes` ships `one-light.yaml` (verified via `nix-darwin` MCP search → `base16-schemes 0-unstable-2026-01-15` includes One Light).

**Consistency note**: Both hosts will theme identically because both reference the same scheme content — `thiniel` via inline duplication, `J6G6Y9JK7L` via the upstream file. A future cleanup MAY centralise this into `lib/themes/one-light.nix` (out of scope here; tracked as follow-up).

### 3.3 Stylix Image (Wallpaper)

#### `thiniel`

Catppuccin shipped a dedicated wallpaper `pkgs.nixos-artwork.wallpapers.catppuccin-latte`. **There is no equivalent `one-light` wallpaper** in `nixos-artwork`. Three viable replacements, in order of preference:

| Option | Source | Pros | Cons |
|--------|--------|------|------|
| A. Solid `#fafafa` (mirrors macOS host) | `pkgs.runCommand` + imagemagick | Maximally consistent with the One Light palette; matches `J6G6Y9JK7L` | Plain — no visual interest |
| B. `pkgs.nixos-artwork.wallpapers.simple-light-gray` | nixos-artwork | Neutral, ships with nixos-artwork | Slightly cool grey, not exact `#fafafa` |
| C. User-provided image file | `./wallpapers/one-light.jpg` in repo | Fully custom | Requires sourcing/licensing an image |

**Plan default: Option A** (solid `#fafafa` generated via `imagemagick`). This achieves cross-host consistency with `J6G6Y9JK7L` and the user can swap to a custom image later as a one-line change. The pattern is already proven in [`hosts/J6G6Y9JK7L/default.nix:117`](../../hosts/J6G6Y9JK7L/default.nix:117).

#### `J6G6Y9JK7L`

Already uses a runtime solid-colour wallpaper at [`hosts/J6G6Y9JK7L/default.nix:117`](../../hosts/J6G6Y9JK7L/default.nix:117). Only the hex needs to change: `#eff1f5` → `#fafafa`. The derivation name should also rename for clarity: `solid-latte-wallpaper` → `solid-one-light-wallpaper`.

### 3.4 Stylix Cursor

Currently [`hosts/thiniel/default.nix:498`](../../hosts/thiniel/default.nix:498) uses `pkgs.catppuccin-cursors.latteBlue`. **No `one-light-cursors` package exists** in nixpkgs (verified via MCP). Candidate neutral cursor packages (verified available in unstable):

| Package | Notes |
|---------|-------|
| `pkgs.bibata-cursors` | Material design, neutral, widely used; ships multiple variants (`Bibata-Modern-Classic`, `Bibata-Modern-Ice`, `Bibata-Original-Classic`) |
| `pkgs.whitesur-cursors` | macOS-inspired, light backgrounds |
| `pkgs.graphite-cursors` | Neutral grey |
| `pkgs.capitaine-cursors` | Classic neutral set |

**Plan default**: `pkgs.bibata-cursors` with `name = "Bibata-Modern-Classic"`, `size = 24` (preserves current size). Rationale: most common neutral choice across NixOS configs, well-tested with both Hyprland and Wayland cursor handling, ships several light/dark variants if user wants to fine-tune later.

`J6G6Y9JK7L` does not declare `stylix.cursor` (macOS handles cursors at the OS level), so no change there.

### 3.5 Vim — From Plugin Override to Stylix-Managed

Current state ([`home/dan/features/cli/vim.nix`](../../home/dan/features/cli/vim.nix:1)):

```nix
stylix.targets.vim.enable = false;     # line 4
programs.vim.plugins = [ catppuccin-vim ];  # line 9
programs.vim.extraConfig = ''
  syntax on
  set termguicolors
  set background=light
  colorscheme catppuccin_latte
  ...
'';
```

Target state:

```nix
# (no stylix.targets.vim.enable override → defaults to autoEnable behaviour)
# Stylix auto-injects base16 vim plugin + colorscheme block
stylix.targets.vim.enable = true;      # explicit opt-in, matches repo convention
programs.vim.plugins = [ ];            # catppuccin-vim removed
programs.vim.extraConfig = ''
  syntax on
  " Stylix injects: set termguicolors / background / colorscheme
  ...
'';
```

The remaining `extraConfig` lines (settings unrelated to colors: `hlsearch`, `mouse=a`, undo/backup/swap directories, `<leader>` mappings) MUST be preserved.

### 3.6 Emacs — Theme Strategy

Current state ([`home/dan/features/productivity/emacs.nix:42`](../../home/dan/features/productivity/emacs.nix:42), [:188](../../home/dan/features/productivity/emacs.nix:188)):

```nix
extraPackages = epkgs: with epkgs; [
  ...
  catppuccin-theme    # line 42
  doom-themes         # kept for doom-modeline
  ...
];
extraConfig = ''
  ...
  (use-package catppuccin-theme
    :config
    (setq catppuccin-flavor 'latte)
    (load-theme 'catppuccin t))   ;; lines 188-191
  ...
'';
```

**Stylix Emacs target status**: Stylix provides `stylix.targets.emacs.enable` that ships a base16-themes-derived Elisp file. **However**, this Stylix target is currently **not** enabled in the repo for `emacs.nix`. Three options:

| Option | Approach | Trade-off |
|--------|----------|-----------|
| A. Replace `catppuccin-theme` with a manual `base16-themes` package + `(load-theme 'base16-one-light t)` | Smallest behavioural shift — keeps full control in Elisp | Needs `base16-themes` epkg; theme name verification |
| B. Enable `stylix.targets.emacs.enable = true` and drop both the package and the load-theme block | Single source of truth (Stylix derives from `base16Scheme`) | Adds an auto-generated `~/.emacs.d/stylix.el` and the `programs.emacs.extraPackages` must include `base16-themes` for the underlying theme |
| C. Use `doom-themes` (already in extraPackages for `doom-modeline`) with a light theme like `doom-one-light` | Reuses existing dependency | Not driven by `stylix.base16Scheme`; drifts from system palette |

**Plan default: Option A** (manual `base16-themes` + `(load-theme 'base16-one-light t)`). Rationale:
- Minimal blast radius — single-file, single-package replacement
- Keeps `extraConfig` Elisp source-controlled and human-auditable
- Avoids enabling a brand-new Stylix target that may surface unrelated regressions in the same change
- The Emacs `base16-themes` epkg (Emacs package) provides `base16-one-light` as a theme name — verify in Phase 0

If Option A reveals theme-name mismatch during Phase 1 Red verification, escalate to Orchestrator to pick between Option B and Option C before continuing.

### 3.7 Files Under Modification — Summary

| # | File | Change Class | Notes |
|---|------|--------------|-------|
| 1 | [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix:451) | Palette + image + cursor | Inline base16 attrset, wallpaper to solid `#fafafa`, cursor to `bibata-cursors` |
| 2 | [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:112) | Palette path + image hex | `catppuccin-latte.yaml` → `one-light.yaml`, `#eff1f5` → `#fafafa`, derivation rename |
| 3 | [`home/dan/features/cli/vim.nix`](../../home/dan/features/cli/vim.nix:1) | Drop plugin override; enable Stylix vim target | Both hosts impacted (vim.nix is imported by both `thiniel.nix` and `J6G6Y9JK7L.nix`) |
| 4 | [`home/dan/features/productivity/emacs.nix`](../../home/dan/features/productivity/emacs.nix:1) | Theme swap | `J6G6Y9JK7L` only (the `emacs.nix` module is **not** imported by `thiniel.nix`); `J6G6Y9JK7L` imports `emacs-doom.nix` (Doom — see §7) AND optionally `emacs.nix` — verify import graph in Phase 1 |
| 5 | [`tests/unit/hm-cli-modules-test.nix`](../../tests/unit/hm-cli-modules-test.nix:242) | Test invariants | Remove `testVimExtraConfigCatppuccin`, `testVimHasCatppuccinPlugin`; add Stylix-managed equivalents |
| 6 | [`tests/assertions/thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix:14) | Comment-only update | Assertion text mentions "Catppuccin Latte" — rewrite to "One Light"; the `polarity == "light"` assertion itself is unchanged |
| 7 | [`home/dan/features/macos/defaults.nix`](../../home/dan/features/macos/defaults.nix:8) | Comment-only update | Comment references Catppuccin lavender; refresh wording (no functional change) |

**Out of automation scope** (documented; manual user actions):

| # | File / Surface | Action |
|---|----------------|--------|
| M1 | [`home/dan/features/productivity/vscode.nix`](../../home/dan/features/productivity/vscode.nix:1) | User-installed marketplace theme; manual swap to "Atom One Light" or "One Light Pro" via VS Code UI; update inline comment in `vscode.nix` (line 3) to reflect One Light recommendation |
| M2 | [`home/dan/features/productivity/browser.nix`](../../home/dan/features/productivity/browser.nix:8) | Firefox theme/addon manually installed; comment update + user action to install One Light addon (e.g., search "Atom One Light" on AMO) |
| M3 | [`home/dan/dotfiles/doom.d/config.el`](../../home/dan/dotfiles/doom.d/config.el:57) and [`packages.el`](../../home/dan/dotfiles/doom.d/packages.el:48) | Doom Emacs is managed via `straight.el`, **not Nix** ([`home/dan/features/productivity/emacs-doom.nix:8`](../../home/dan/features/productivity/emacs-doom.nix:8)). Doom config changes are out of scope for the Nix migration. Tracked in §7 as a follow-up item — the user runs `doom sync` after editing these files manually |

### 3.8 Import-Graph Verification (Pre-Phase 0)

Before starting Phase 1, the Code mode MUST verify (read-only):

- [`home/dan/thiniel.nix`](../../home/dan/thiniel.nix:1) — does it import `emacs.nix`? **Answer**: No (line 12 imports `vim.nix` only; no `emacs.nix` import). → `emacs.nix` changes do not affect `thiniel`.
- [`home/dan/J6G6Y9JK7L.nix`](../../home/dan/J6G6Y9JK7L.nix:1) — does it import `emacs.nix`? **Answer**: No (line 34 imports `emacs-doom.nix`; `emacs.nix` is **not** imported by any active host profile).
- **Implication**: `emacs.nix` is currently dead code from a host-import perspective. The plan still updates it (acceptance criterion 7) for consistency, but Phase 4 Green verification cannot rely on a host-level rebuild to surface theme errors — it must use a `home-manager` eval against the module in isolation, OR the file may simply be deleted as a follow-up (out of scope here).

## 4. Risk & Dangerous-Change Assessment

| Category | Affected? | Notes |
|----------|-----------|-------|
| Boot | No | Pure theming change |
| Network | No | — |
| Filesystem | No | — |
| Authentication | No | hyprlock continues to be Stylix-themed; only colours change |
| Secrets | No | — |
| Session loss (low) | Yes | A typo in the base16 attrset on `thiniel` would fail `nix flake check` before activation; if applied, Stylix may fall back to defaults but won't break the WM. `nixos-rebuild test` mitigates. |
| Visual regression (moderate) | Yes | Some apps may look subtly worse on generic base16 than on a dedicated theme — see §4.1 |
| Cross-host eval (low) | Yes | If `thiniel`'s inline scheme is accidentally replaced with `"${pkgs.base16-schemes}/share/themes/one-light.yaml"`, evaluating `thiniel` from macOS will require IFD or `--no-build`. Mitigation: keep inline form (acceptance criterion implied via §3.2) |

### 4.1 Visual Regression Risk Matrix — "What if it looks bad on generic base16?"

Stylix maps the 16 base slots onto each app's colour requirements via opinionated heuristics. Some apps were originally tuned by their respective theme authors (Catppuccin) and may look subtly less polished on auto-generated base16 mappings.

| App | Risk | Mitigation |
|-----|------|------------|
| **kitty** | Low | base16-kitty is well-established; One Light's ANSI mapping is direct |
| **fish/starship** | Low | Both consume base16 via Stylix natively |
| **bat/fzf/lazygit** | Low | All have base16 ports; tested broadly |
| **vim** (Stylix-generated) | **Medium** | Catppuccin-vim was hand-crafted by upstream; generic base16-vim may have less syntax-group differentiation. Mitigation: if visually unacceptable after Phase 3, fall back to keeping `stylix.targets.vim.enable = false` and using a dedicated `vim-one` plugin (`pkgs.vimPlugins.vim-one`). Track as Phase 3 contingency. |
| **Emacs** (base16-themes) | **Medium** | Comparable to vim risk. `base16-one-light` is the official upstream base16 variant — fidelity should be high. Contingency: use Atom-derived `atom-one-light-theme` epkg if available. |
| **Hyprland borders** | Low | Just colour values |
| **waybar** | Low | Stylix injects CSS variables; layout untouched |
| **mako/fuzzel/hyprlock** | Low | Stylix targets are stable |
| **GTK/Qt** | **Medium** | Catppuccin Latte had a dedicated GTK theme; generic base16 GTK falls back to Adwaita + base16 accents. Mitigation: this is a known Stylix behaviour — visually acceptable for ordinary use; user can manually pin a different GTK theme if needed (out of scope). |
| **Cursor** (`bibata-cursors`) | Low | Bibata is a popular drop-in replacement; visual style is "modern macOS-like" |

### 4.2 Rollback Path

| Trigger | Action |
|---------|--------|
| `nix flake check` fails after a Red-Green cycle | `git restore <files>` then re-attempt |
| `nixos-rebuild switch` succeeds but visual result is unacceptable | `sudo nixos-rebuild --rollback switch` (instant revert to previous generation) |
| `darwin-rebuild switch` succeeds but visual result is unacceptable | `darwin-rebuild --rollback` (or `darwin-rebuild switch` with previous flake ref) |
| Single app looks broken after all phases pass | Revert that app's specific change (e.g., re-disable Stylix vim target, restore `catppuccin-vim` plugin) — atomic per-app rollback enabled by phase structure |

---

## 5. Validation Strategy (Phase 0 — BEFORE any code change)

### 5.1 Per-Cycle Validation Commands

| Layer | Command | Purpose |
|-------|---------|---------|
| Syntax/eval | `nix flake check --no-build` | Fast — catches Nix eval errors, runs all assertions |
| Unit tests | `nix build .#checks.x86_64-linux.unit-tests-hm-cli-modules` (or whichever check name the file registers under) | Catches vim/emacs unit test regressions |
| `thiniel` build | `nix build .#nixosConfigurations.thiniel.config.system.build.toplevel` | Catches HM evaluation errors for Linux host |
| `J6G6Y9JK7L` build | `nix build .#darwinConfigurations.J6G6Y9JK7L.system` (on macOS) OR `nix flake check` cross-eval (on Linux) | Catches HM evaluation errors for macOS host |
| Full check | `nix flake check` | Runs assertions, evals all configurations, runs integration tests |
| Quality | `nix fmt && statix check && deadnix .` | Repo hygiene |

### 5.2 Pre-Phase 0 Verification Tasks

Before starting Phase 1, Code mode MUST confirm:

- [ ] `pkgs.base16-schemes` contains `share/themes/one-light.yaml` (run: `nix eval --raw 'nixpkgs#base16-schemes' --apply 'p: builtins.readDir "${p}/share/themes"' | grep one-light`)
- [ ] `pkgs.bibata-cursors` exists in the pinned nixpkgs (run: `nix eval 'nixpkgs#bibata-cursors.meta.description'`)
- [ ] Emacs `base16-themes` epkg is available (run: `nix eval 'nixpkgs#emacsPackages.base16-theme.version'`) and the loadable theme name is `base16-one-light` (inspect the package's elisp source or a quick `emacs -batch` probe)
- [ ] Import graph: `grep -rn 'emacs.nix' home/dan/*.nix` returns no host-level import (confirms §3.8)
- [ ] The exact Catppuccin hex values to be removed do not appear in any other file: `grep -rn '#eff1f5\|#4c4f69\|#1e66f5\|#7287fd\|#d20f39\|catppuccin_latte\|catppuccin-vim\|catppuccin-cursors\|catppuccin-theme' hosts/ home/ tests/`

If any precondition fails, STOP and report to Orchestrator before continuing.

### 5.3 Final Apply Sequence

| Step | Command |
|------|---------|
| Test on `thiniel` (non-persistent) | `sudo nixos-rebuild test --flake .#thiniel` |
| Visual check (§5.4) | (manual) |
| Switch on `thiniel` (persistent) | `sudo nixos-rebuild switch --flake .#thiniel` |
| Apply on `J6G6Y9JK7L` | `darwin-rebuild switch --flake .#J6G6Y9JK7L` |
| Rollback (NixOS) | `sudo nixos-rebuild --rollback switch` |
| Rollback (Darwin) | `darwin-rebuild --rollback` |

### 5.4 Post-Apply Manual Visual Checklist (cannot be automated)

On `thiniel` (Hyprland session):

- [ ] Wallpaper renders as solid near-white `#fafafa`
- [ ] kitty terminal: background `#fafafa`, text `#383a42`, comments `#a0a1a7`
- [ ] waybar: light theme, accent colours from One Light
- [ ] fuzzel launcher: light background, blue accent (`#4078f2`)
- [ ] mako notifications: light card, dark text
- [ ] hyprlock: light lock screen, no Catppuccin tinting
- [ ] Hyprland window borders: active = blue-ish (`#4078f2`), inactive = light grey
- [ ] Cursor: Bibata Modern Classic shape visible (not the previous Catppuccin Latte Blue cursor)
- [ ] vim (run `vim`): syntax highlighted with One Light colours, no error about missing `catppuccin_latte`
- [ ] GTK app (e.g., `nautilus` or `gnome-text-editor`): light theme
- [ ] Qt app (e.g., `keepassxc`): light theme

On `J6G6Y9JK7L` (macOS):

- [ ] kitty terminal: One Light palette
- [ ] vim: One Light syntax highlighting
- [ ] Emacs (`emacsclient -c`): One Light theme loaded (if `emacs.nix` is imported)

---

## 6. Implementation Phases

> **TDD discipline** ([TEST-FIRST-001](../../.roo/rules/13-test-first.md)): one assertion/test per Red-Green cycle. Test written FIRST, observed to FAIL, then implementation makes it PASS, then quality gates run. Commit after each completed cycle ([`02-commits.md`](../../.roo/rules/02-commits.md)).
>
> **Atomicity guidance**: Where a single conceptual change requires touching multiple coupled lines (e.g., replacing all 16 hex values in one attrset), one cycle is acceptable provided the test asserts the whole new state in one expression (e.g., `config.stylix.base16Scheme.base05 == "383a42"` + `config.stylix.base16Scheme.scheme == "One Light"` combined into one assertion). Per-slot cycles are over-fragmentation here.

### Phase 1 — Pre-Verification & Scaffolding

| Step | Action | Verify |
|------|--------|--------|
| 1.1 | Run all Phase 0 (§5.2) precondition checks. | All checks pass; report results before continuing. |
| 1.2 | Audit current state: `grep -rn 'catppuccin\|catppuccin_latte\|eff1f5\|4c4f69\|d20f39\|7287fd' hosts/ home/ tests/` — capture baseline list of references. | Baseline list documented in Completion Log §9. |
| 1.3 | No code change. | — |

### Phase 2 — `thiniel` Host Stylix Block

#### Cycle 2.1 — base16 palette swap (one cycle)

| Sub-Step | Action |
|----------|--------|
| 2.1.R | Add a new assertion to [`tests/assertions/thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix:1): `config.stylix.base16Scheme.scheme == "One Light" && config.stylix.base16Scheme.base00 == "fafafa" && config.stylix.base16Scheme.base05 == "383a42" && config.stylix.base16Scheme.base0D == "4078f2"`. Run `nix flake check --no-build` → MUST FAIL (current scheme is "Catppuccin Latte"). |
| 2.1.G | In [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix:457), replace the entire `base16Scheme = { … };` attrset with the 16 One Light hex values from §3.1 plus `scheme = "One Light";` and `author = "Daniel Pfeifer (http://github.com/purpleKarrot)";`. Update the leading comment from "Catppuccin Latte" to "One Light". Run `nix flake check --no-build` → PASS. |
| 2.1.Q | `nix fmt && statix check && deadnix .` — clean. |
| 2.1.C | Commit: `feat(thiniel): switch stylix base16Scheme to One Light`. |

#### Cycle 2.2 — wallpaper swap

| Sub-Step | Action |
|----------|--------|
| 2.2.R | Add assertion to [`tests/assertions/thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix:1): the derivation name of `config.stylix.image` does NOT contain `"catppuccin-latte"`. Example: `assertion = !(lib.strings.hasInfix "catppuccin-latte" (toString config.stylix.image));`. Run `nix flake check --no-build` → MUST FAIL. |
| 2.2.G | In [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix:477), replace `pkgs.nixos-artwork.wallpapers.catppuccin-latte.gnomeFilePath` with: `pkgs.runCommand "solid-one-light-wallpaper" { nativeBuildInputs = [ pkgs.imagemagick ]; } "magick -size 1920x1080 xc:#fafafa $out"`. Run `nix flake check --no-build` → PASS. |
| 2.2.Q | Quality gates. |
| 2.2.C | Commit: `feat(thiniel): replace wallpaper with solid One Light background`. |

#### Cycle 2.3 — cursor swap

| Sub-Step | Action |
|----------|--------|
| 2.3.R | Add assertion: `config.stylix.cursor.name == "Bibata-Modern-Classic"` AND `(config.stylix.cursor.package.pname or "") != "catppuccin-cursors"`. Run `nix flake check --no-build` → MUST FAIL. |
| 2.3.G | In [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix:498), replace the cursor block: `package = pkgs.bibata-cursors; name = "Bibata-Modern-Classic"; size = 24;`. Run `nix flake check --no-build` → PASS. |
| 2.3.Q | Quality gates. |
| 2.3.C | Commit: `feat(thiniel): switch cursor theme to Bibata Modern Classic`. |

#### Cycle 2.4 — assertion comment refresh

| Sub-Step | Action |
|----------|--------|
| 2.4.R | Search [`tests/assertions/thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix:14) for the substring `"Catppuccin Latte"` in any assertion `message`. Add a meta-assertion (or a `runTests`-style check in a unit test) verifying no test message contains "Catppuccin Latte". If a meta-assertion isn't ergonomic, this cycle may be a pure refactor (no Red phase) — document the deviation. |
| 2.4.G | Replace assertion `message`s in [`tests/assertions/thiniel-rice-invariants.nix`](../../tests/assertions/thiniel-rice-invariants.nix:1) line 14 (and the file header comment on line 2) to read "One Light" instead of "Catppuccin Latte". Run `nix flake check --no-build` → PASS. |
| 2.4.Q | Quality gates. |
| 2.4.C | Commit: `chore(tests): rename thiniel rice assertion messages to One Light`. |

### Phase 3 — `J6G6Y9JK7L` Host Stylix Block

#### Cycle 3.1 — base16Scheme file path

| Sub-Step | Action |
|----------|--------|
| 3.1.R | Add a J6G6Y9JK7L-scoped assertion (extend [`tests/assertions/J6G6Y9JK7L-invariants.nix`](../../tests/assertions/J6G6Y9JK7L-invariants.nix:1) — guard with `lib.mkIf (config.networking.hostName == "J6G6Y9JK7L")` or the darwin equivalent) asserting `lib.strings.hasInfix "one-light.yaml" (toString config.stylix.base16Scheme)`. Run `nix flake check --no-build` → MUST FAIL. |
| 3.1.G | In [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:116), change the file path suffix from `catppuccin-latte.yaml` to `one-light.yaml`. Update inline comment "Catppuccin Latte" → "One Light". Run `nix flake check --no-build` → PASS. |
| 3.1.Q | Quality gates. |
| 3.1.C | Commit: `feat(J6G6Y9JK7L): switch stylix base16Scheme to One Light`. |

#### Cycle 3.2 — wallpaper hex + derivation rename

| Sub-Step | Action |
|----------|--------|
| 3.2.R | Add assertion: `!(lib.strings.hasInfix "eff1f5" (config.stylix.image.drvAttrs.buildCommand or ""))`. (Alternative: assert the derivation `name` field equals `"solid-one-light-wallpaper"`.) Run `nix flake check --no-build` → MUST FAIL. |
| 3.2.G | In [`hosts/J6G6Y9JK7L/default.nix`](../../hosts/J6G6Y9JK7L/default.nix:117), rename derivation to `solid-one-light-wallpaper` and change `xc:#eff1f5` → `xc:#fafafa`. Run `nix flake check --no-build` → PASS. |
| 3.2.Q | Quality gates. |
| 3.2.C | Commit: `feat(J6G6Y9JK7L): switch wallpaper solid colour to One Light #fafafa`. |

### Phase 4 — Vim Migration (cross-host module)

This single file ([`home/dan/features/cli/vim.nix`](../../home/dan/features/cli/vim.nix:1)) affects both hosts. Validation must build BOTH hosts' configurations.

#### Cycle 4.1 — remove `stylix.targets.vim.enable = false;` and the `catppuccin-vim` plugin

| Sub-Step | Action |
|----------|--------|
| 4.1.R | Update [`tests/unit/hm-cli-modules-test.nix`](../../tests/unit/hm-cli-modules-test.nix:242): **delete** `testVimExtraConfigCatppuccin` and `testVimHasCatppuccinPlugin`. **Add** new tests: (a) `testVimStylixTargetEnabled` asserting `vimModule.stylix.targets.vim.enable == true`; (b) `testVimNoCatppuccinPlugin` asserting `!(builtins.any (p: (p.pname or p.name or "") == "catppuccin-vim") vimModule.programs.vim.plugins)`; (c) `testVimExtraConfigHasNoColorscheme` asserting `!(lib.strings.hasInfix "colorscheme catppuccin_latte" vimModule.programs.vim.extraConfig)`. Run `nix flake check --no-build` → MUST FAIL on all three new tests. |
| 4.1.G | In [`home/dan/features/cli/vim.nix`](../../home/dan/features/cli/vim.nix:1): (a) change line 4 to `stylix.targets.vim.enable = true;`; (b) remove `catppuccin-vim` from `plugins` list (line 9 becomes `plugins = [ ];` — or remove the attribute entirely if no plugins remain); (c) remove from `extraConfig` (lines 27-30): the `" Catppuccin Latte colorscheme"` comment, `set termguicolors`, `set background=light`, `colorscheme catppuccin_latte`. Preserve ALL other `extraConfig` lines (hlsearch, mouse, undo/backup/swap, leader). Run `nix flake check --no-build` → PASS. |
| 4.1.Q | Quality gates + run `nix build .#nixosConfigurations.thiniel.config.system.build.toplevel` AND `nix build .#darwinConfigurations.J6G6Y9JK7L.system` (or cross-eval equivalent) — both must PASS. |
| 4.1.C | Commit: `feat(vim): switch from catppuccin-vim plugin to Stylix-managed One Light`. |

#### Cycle 4.2 — contingency check

| Sub-Step | Action |
|----------|--------|
| 4.2.M | After applying on `thiniel` (in Final Phase), launch `vim` and inspect highlighting. If syntax differentiation is visually unacceptable, FALL BACK: re-set `stylix.targets.vim.enable = false`, add `pkgs.vimPlugins.vim-one` to plugins, add `colorscheme one` to `extraConfig`. Document the fallback decision in Completion Log §9. |

### Phase 5 — Emacs Migration

Single-cycle change to [`home/dan/features/productivity/emacs.nix`](../../home/dan/features/productivity/emacs.nix:1). Note §3.8: this module is **not currently imported by any host profile**, so validation falls back to standalone module eval.

#### Cycle 5.1 — replace `catppuccin-theme` with `base16-themes` + `base16-one-light`

| Sub-Step | Action |
|----------|--------|
| 5.1.R | Add a unit test to [`tests/unit/hm-cli-modules-test.nix`](../../tests/unit/hm-cli-modules-test.nix:1) (or a new file `tests/unit/hm-productivity-modules-test.nix`): (a) `testEmacsNoCatppuccinTheme` asserting `!(builtins.any (p: ((p.pname or "") == "catppuccin-theme") || ((p.ename or "") == "catppuccin-theme")) (emacsModule.programs.emacs.extraPackages or epkgs: [ ]) epkgs)`; (b) `testEmacsExtraConfigNoCatppuccin` asserting `!(lib.strings.hasInfix "catppuccin" emacsModule.programs.emacs.extraConfig)`. Run `nix flake check --no-build` → MUST FAIL. *Mocking note*: instantiating the emacs module requires providing `epkgs` — see existing unit-test mocking patterns. If too complex, fall back to a grep-based test against the file source string. |
| 5.1.G | In [`home/dan/features/productivity/emacs.nix`](../../home/dan/features/productivity/emacs.nix:1): (a) replace `catppuccin-theme # Catppuccin Latte theme` (line 42) with `base16-theme # One Light via base16 family`; (b) replace the `(use-package catppuccin-theme …)` block (lines 188-191) with `(use-package base16-theme :config (load-theme 'base16-one-light t))`; (c) update comment "Catppuccin Latte" → "One Light" on line 42. Run `nix flake check --no-build` → PASS. |
| 5.1.Q | Quality gates. |
| 5.1.C | Commit: `feat(emacs): switch theme from catppuccin-latte to base16 One Light`. |

### Phase 6 — Documentation-Only Refresh

#### Cycle 6.1 — comment cleanup (no code change)

| Sub-Step | Action |
|----------|--------|
| 6.1.R | Skip Red (pure refactor — comment text only). Document the deviation. |
| 6.1.G | Update comments in: |
|        | – [`home/dan/features/macos/defaults.nix`](../../home/dan/features/macos/defaults.nix:8): rewrite the comment about Catppuccin Latte lavender — either remove or rephrase as a generic neutral comment. |
|        | – [`home/dan/features/productivity/vscode.nix`](../../home/dan/features/productivity/vscode.nix:2-3): change the marketplace install hint from "Catppuccin for VSCode" / "Catppuccin Latte" to "Atom One Light" (or user-preferred One Light variant). |
|        | – [`home/dan/features/productivity/browser.nix`](../../home/dan/features/productivity/browser.nix:8): change "install Catppuccin Latte addon" to "install One Light addon". |
|        | Run `nix flake check --no-build` → PASS (no behaviour change). |
| 6.1.Q | Quality gates. |
| 6.1.C | Commit: `docs: update theme references from Catppuccin Latte to One Light`. |

### Phase 7 — Negative Sweep

#### Cycle 7.1 — repo-wide residue check

| Sub-Step | Action |
|----------|--------|
| 7.1.R | Add a Python or Nix test that fails if `grep -rE 'catppuccin[-_]?(latte|theme|vim|cursors)' hosts/ home/dan/features home/dan/global home/dan/*.nix tests/` returns any match (excluding `home/dan/dotfiles/` — see §7). If a Nix-side test is impractical, document this as a manual pre-merge check in the Completion Log. Run → MUST FAIL or be inconclusive — verify the grep output is empty after Phases 2-6. |
| 7.1.G | If grep returns matches, address each one in its own atomic cycle. If empty, this phase is a verification-only no-op. |
| 7.1.C | Commit: `test: assert no catppuccin residue in nix-managed paths` (if a test was added) OR no commit needed (if pure verification). |

### Final Phase — Apply & Verify

| Step | Action |
|------|--------|
| F.1 | `nix flake check` — PASS (full check). |
| F.2 | `nix build .#nixosConfigurations.thiniel.config.system.build.toplevel` — PASS. |
| F.3 | `nix build .#darwinConfigurations.J6G6Y9JK7L.system` (on macOS) — PASS. |
| F.4 | `sudo nixos-rebuild test --flake .#thiniel`. |
| F.5 | Execute the visual checklist in §5.4 on `thiniel`. |
| F.6 | If visually acceptable: `sudo nixos-rebuild switch --flake .#thiniel`. |
| F.7 | If `vim` looks bad: execute Cycle 4.2 fallback, repeat from F.1. |
| F.8 | On `J6G6Y9JK7L` machine: `darwin-rebuild switch --flake .#J6G6Y9JK7L`. |
| F.9 | Manual UI actions: install One Light VS Code theme (M1), install One Light Firefox addon (M2), optionally update Doom config (M3 — out of scope). |
| F.10 | Update Completion Log §9. |

---

## 7. Out of Scope

- Doom Emacs theme migration ([`home/dan/dotfiles/doom.d/config.el`](../../home/dan/dotfiles/doom.d/config.el:57), [`packages.el`](../../home/dan/dotfiles/doom.d/packages.el:48)) — Doom is managed by `straight.el`, not Nix; tracked as a follow-up task for the user.
- VS Code marketplace theme — manual user action.
- Firefox theme addon — manual user action.
- macOS system accent colour (`AppleAccentColor`) — currently Graphite; no change unless user requests an Atom One Light blue accent (would need separate decision).
- Refactoring the duplicated base16Scheme content into a shared `lib/themes/one-light.nix` module — separate cleanup task; track as a follow-up.
- Deleting the unused [`home/dan/features/productivity/emacs.nix`](../../home/dan/features/productivity/emacs.nix:1) module (see §3.8) — separate cleanup task.
- Migrating to a custom (non-solid) wallpaper for `thiniel` — user can swap as a one-line change post-migration.

---

## 8. Current Status

- [ ] Phase 0: Validation Strategy (this document, plus §5.2 precondition checks)
- [ ] Phase 1: Pre-verification & baseline audit
- [ ] Phase 2: `thiniel` host Stylix block (4 cycles)
- [ ] Phase 3: `J6G6Y9JK7L` host Stylix block (2 cycles)
- [ ] Phase 4: Vim migration (1 cycle + contingency)
- [ ] Phase 5: Emacs migration (1 cycle)
- [ ] Phase 6: Documentation comment refresh (1 cycle)
- [ ] Phase 7: Negative sweep (1 cycle)
- [ ] Final Phase: Apply & verify

## 9. Completion Log

_To be filled in by Code Mode as phases complete._

| Phase | Status | Notes / Deviations |
|-------|--------|--------------------|
| 0 | — | — |
| 1 | — | — |
| 2 | — | — |
| 3 | — | — |
| 4 | — | — |
| 5 | — | — |
| 6 | — | — |
| 7 | — | — |
| Final | — | — |
