# Plan: Behebung der SSH-Key-Auswahl für GitHub Multi-Identity (macOS J6G6Y9JK7L)

**Status:** Implementiert  
**Host:** `J6G6Y9JK7L` (macOS/nix-darwin)  
**Datum:** 2026-10-04  

## Context
Auf der macOS-Workstation `J6G6Y9JK7L` wurden bei Git-Operationen gegen GitHub die falschen SSH-Schlüssel verwendet (z. B. der Firmen-Schlüssel statt des privaten Schlüssels).

Der Benutzer hat den neuen privaten Schlüssel `~/.ssh/id_ed25519_personal_2026-10-04` generiert und den alten Schlüssel entfernt.
Beim Versuch `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal_2026-10-04` trat der Fehler `agent refused operation` auf.

### Ursachenanalyse
1. **`agent refused operation` bei `ssh-add`:**
   In `home/dan/features/productivity/emacs-doom.nix` war `services.gpg-agent.enableSshSupport = true;` aktiv.
   Dadurch setzte die Shell `SSH_AUTH_SOCK` auf den GPG-Agent-Socket (`~/.gnupg/S.gpg-agent.ssh`). Der GPG-Agent unterstützt die Apple-Keychain-Flags (`--apple-use-keychain`) von `/usr/bin/ssh-add` nicht und verweigert die Operation.
   Nach Entfernen von `enableSshSupport` greift der native macOS SSH-Agent über `launchd` wieder unbeeinflusst.
2. **Invertierte `insteadOf`-Direktive in `home/dan/features/cli/git.nix`:**
   In den Profil-Templates (`git-personal`, `git-company`, `git-client001`, `git-client002`) war `insteadOf` syntaktisch verkehrt herum definiert:
   `[url "git@github.com:"] insteadOf = git@github-personal:` ersetzte `github-personal` durch `github.com`, statt Standard-URLs auf den Host-Alias umzuleiten. Standard-Remotes (`git@github.com:...`) wurden daher nicht umgeschrieben. Bei `client002` existierte zudem ein Tippfehler (`gbitbucket-client002`).
3. **Fehlendes `IdentitiesOnly` unter `Host *` in `home/dan/features/cli/ssh.nix`:**
   Da Verbindungen direkt an `github.com` gingen, griff kein `Host github-*`-Block, sondern ausschließlich `Host *`. Dort fehlte `IdentitiesOnly = true`. SSH fragte den Agenten ab, der alle geladenen Keys der Reihe nach anbot; GitHub akzeptierte den ersten passenden Schlüssel.
4. **Veralteter Pfad des Personal Keys in der Nix-Konfiguration:**
   In `ssh.nix` und den Git-Configs war noch der alte Dateiname `~/.ssh/id_ed25519_personal_2025-06-18` referenziert, der vom Benutzer bereits durch `~/.ssh/id_ed25519_personal_2026-10-04` ersetzt wurde.

---

## Ziel-Architektur

### 1. GPG-Agent SSH-Support deaktivieren (`home/dan/features/productivity/emacs-doom.nix`)
- `services.gpg-agent.enableSshSupport = true;` entfernen.
- `SSH_AUTH_SOCK` bleibt unbeeinflusst und verweist auf den nativen macOS `launchd`-Socket.
- `ssh-add --apple-use-keychain` und Apple Keychain funktionieren wieder wie vorgesehen.

### 2. Git-Konfiguration (`home/dan/features/cli/git.nix`)
In den SOPS-Templates für die Identitäts-Configs (`git-personal`, `git-company`, `git-client001`, `git-client002`):
- `core.sshCommand` setzen:
  - `git-personal`: `ssh -i ~/.ssh/id_ed25519_personal_2026-10-04 -o IdentitiesOnly=yes`
  - `git-company`: `ssh -i ~/.ssh/id_ed25519_company_2025-06-18 -o IdentitiesOnly=yes`
  - `git-client001`: `ssh -i ~/.ssh/id_ed25519_client001_2025-07-22 -o IdentitiesOnly=yes`
  - `git-client002`: `ssh -i ~/.ssh/id_ed25519_client002_2026-01-13 -o IdentitiesOnly=yes`
- `insteadOf` korrigieren:
  - `[url "git@github-personal:"] insteadOf = git@github.com:` (und analog für die weiteren Identitäten).
- Tippfehler bei `git-client002` (`gbitbucket-client002` -> `bitbucket-client002`) beheben.

### 3. SSH-Konfiguration anpassen (`home/dan/features/cli/ssh.nix`)
- In `programs.ssh.settings."github-personal"` den Pfad auf `~/.ssh/id_ed25519_personal_2026-10-04` aktualisieren.
- In `programs.ssh.settings."*"` für Darwin `IdentitiesOnly = true;` setzen (einheitlicher Boolean-Typ für Home Manager SSH-Optionen).

---

## Betroffene Dateien
- `home/dan/features/productivity/emacs-doom.nix`
- `home/dan/features/cli/git.nix`
- `home/dan/features/cli/ssh.nix`
- `tests/assertions/J6G6Y9JK7L-invariants.nix`
- `tests/unit/hm-cli-modules-test.nix`

---

## Testgetriebene Umsetzung (Red-Green-Refactor)

### Zyklus 1: GPG-Agent SSH-Support deaktivieren
- **Red:** Assertion in `tests/assertions/J6G6Y9JK7L-invariants.nix` ergänzen:
  `!config.services.gpg-agent.enableSshSupport`
  Validierung: `nix flake check --no-build` schlägt fehl (FAIL).
- **Green:** In `home/dan/features/productivity/emacs-doom.nix` `enableSshSupport = true;` entfernen.
  Validierung: `nix flake check --no-build` erfolgreich (PASS).
- **Refactor:** Commit: `6c8a9cf` (`fix(emacs-doom): disable gpg-agent ssh support on darwin`).

### Zyklus 2: SSH-Host-Eintrag für Personal Key aktualisieren
- **Red:** Assertion / Unit-Test prüfen, dass Personal Key `~/.ssh/id_ed25519_personal_2026-10-04` referenziert wird.
- **Green:** In `home/dan/features/cli/ssh.nix` den Pfad aktualisieren und `IdentitiesOnly` auf Darwin `Host *` setzen.
- **Refactor:** Commit: `8c9182f` (`fix(ssh): update personal key path to 2026-10-04 and enforce IdentitiesOnly on darwin`).

### Zyklus 3: Git-Templates korrigieren (core.sshCommand & insteadOf)
- **Red:** Unit-Test in `tests/unit/hm-cli-modules-test.nix` erweitern (prüft `core.sshCommand` und korrektes `insteadOf`).
  Validierung: `nix build .#checks.aarch64-darwin.unit-helpers --no-link` schlägt fehl (FAIL).
- **Green:** `home/dan/features/cli/git.nix` anpassen:
  - `core.sshCommand` pro Template hinzufügen
  - `insteadOf`-Richtung korrigieren
  - Tippfehler `gbitbucket` beheben.
  Validierung: `nix build .#checks.aarch64-darwin.unit-helpers --no-link` erfolgreich (PASS).
- **Refactor:** Commit: `9932062` (`fix(git): isolate ssh keys via core.sshCommand and fix insteadOf mapping`).

### Zyklus 4: Typbereinigung & Refactoring
- **Refactor:** `IdentitiesOnly` in `ssh.nix` und Unit-Test auf einheitlichen Boolean-Typ migrieren.
- Commit: `9ab75da` (`refactor(ssh): unify IdentitiesOnly to boolean type`).

### Zyklus 5: Globale Validierung & System-Build
- `nix flake check` erfolgreich abgeschlossen.
- `darwin-rebuild build --flake .#J6G6Y9JK7L` erfolgreich abgeschlossen.

---

## Verifikation
1. `nix flake check` läuft fehlerfrei durch.
2. `darwin-rebuild build --flake .#J6G6Y9JK7L` baut erfolgreich.
3. Nach `sudo darwin-rebuild switch --flake .#J6G6Y9JK7L`:
   - `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_personal_2026-10-04` gelingt fehlerfrei.
   - `git fetch` im privaten Verzeichnis nutzt den 2026-10-04 Key.
   - `ssh -T git@github-personal` bestätigt den privaten GitHub-Account.
