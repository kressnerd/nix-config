# score-compose Brew-Tap-Trust deklarativ konfigurieren

**Status:** Implementiert  
**Host:** `J6G6Y9JK7L` (macOS/nix-darwin)  
**Scope:** Einzeilige Konfigurationsänderung in `nix-homebrew`-Block

---

## Problem

`sudo darwin-rebuild switch --flake .#J6G6Y9JK7L` schlug im Homebrew-Bundle-Schritt fehl:

```
Error: Refusing to load formula score-spec/tap/score-compose from untrusted tap score-spec/tap.
Run `brew trust --formula score-spec/tap/score-compose` or `brew trust score-spec/tap` to trust it.
```

Ursache: Homebrew 6.0 (via `brew-src`-Pin `6.0.1` in `nix-homebrew`) erzwingt expliziten Trust für Formeln aus Drittanbieter-Taps. Der Tap war bereits gepinnt und deklariert — nur der Trust-Eintrag in `~/.homebrew/trust.json` fehlte.

---

## Lösung

`nix-homebrew` (Revision `de7953a0`) exponiert die Option `nix-homebrew.trust.formulae`. Der Activation-Hook ruft `sudo -n -u <user> brew trust --formula <entry>` auf und schreibt den Eintrag in `trust.json`.

**Änderung** in `hosts/J6G6Y9JK7L/default.nix`, `nix-homebrew`-Block:

```nix
trust.formulae = [ "score-spec/tap/score-compose" ];
```

`trust.formulae` statt `trust.taps` — minimaler Scope. Upstream warnt ausdrücklich davor, dem ganzen Tap zu vertrauen (`trust.taps`) ohne Kenntnis aller gegenwärtigen und zukünftigen Inhalte.

---

## Entschiedene Alternativen

| Option | Warum verworfen |
|---|---|
| `HOMEBREW_NO_REQUIRE_TAP_TRUST=1` | Upstream-dokumentiert als deprecated, "wird in späterer Release entfernt" |
| `brews = [ "score-spec/tap/score-compose" ]` (FQN) | `brew bundle`-Pfad erhält keine implizite Trust — wirkungslos |
| `trust.taps = [ "score-spec/tap" ]` | Zu breiter Scope — vertraut allen zukünftigen Formeln des Taps |

---

## Caveat

Trust-Einträge in `~/.homebrew/trust.json` werden **nicht** automatisch entfernt, wenn man sie aus der Nix-Liste streicht. Manuelle Bereinigung:

```fish
brew untrust --formula score-spec/tap/score-compose
```

---

## Verifikation

Nach `sudo darwin-rebuild switch --flake .#J6G6Y9JK7L`:

```fish
brew trust --json=v1 --formula | grep score-compose   # Entry vorhanden
which score-compose                                     # Tool verfügbar
score-compose --version                                 # Funktional
```
