# Thiniel Laptop Improvements Plan

## Goal

Implement 15 improvements for the ThinkPad X270 (thiniel) laptop running NixOS with Hyprland, following strict TDD Red-Green-Refactor cycles with atomic one-line commits.

## Context

- **Machine**: ThinkPad X270, NixOS 25.11, Hyprland + UWSM, impermanence, OPAL SED FDE
- **Constraint**: No suspend/hibernate (OPAL SED loses encryption key)
- **Principle**: Hyprland-native where possible (exec-once, keybinds, windowrule)
- **Existing**: PipeWire audio, NetworkManager, auto-cpufreq + thermald + powertop, Stylix Catppuccin Latte (autoEnable = false), Fish + Kitty, grim + slurp, wl-clipboard + cliphist, brightnessctl
- **Host config**: `hosts/thiniel/default.nix` (420 lines)
- **HM profile**: `home/dan/thiniel.nix`
- **Assertions**: `tests/assertions/thiniel-*-invariants.nix` (6 files)

## Technical Analysis

### New Files to Create

| File | Purpose |
|------|---------|
| `home/dan/features/productivity/zathura.nix` | PDF viewer with Stylix + mime |
| `home/dan/features/productivity/mpv.nix` | Media player with hwdec + mime |
| `home/dan/features/linux/wlsunset.nix` | Night light via exec-once |
| `home/dan/features/productivity/messaging.nix` | Signal + Threema |
| `home/dan/features/linux/kanshi.nix` | Monitor profiling |
| `home/dan/features/linux/screenshot.nix` | Satty annotations + wf-recorder |
| `tests/assertions/thiniel-hardware-invariants.nix` | Bluetooth, fwupd, battery, WWAN, gestures |
| `tests/assertions/thiniel-desktop-apps-invariants.nix` | Zathura, MPV, messaging, screenshot tools |

### Files to Modify

| File | Changes |
|------|---------|
| `hosts/thiniel/default.nix` | Bluetooth, printing, fwupd, battery thresholds, WWAN, VPN, impermanence entries |
| `home/dan/thiniel.nix` | Import new feature modules |
| `home/dan/features/linux/hyprland.nix` | Touchpad gestures, window rules |
| `home/dan/features/linux/impermanence.nix` | HM-level persistence entries |
| `tests/assertions/default.nix` | Import 2 new assertion files |
| `tests/assertions/thiniel-services-invariants.nix` | Printing/Avahi assertions |
| `tests/assertions/thiniel-impermanence-invariants.nix` | New persistence assertions |
| `tests/assertions/thiniel-rice-invariants.nix` | Hyprland gesture/keybind assertions |

### Key Design Decisions

1. **Battery thresholds**: Use systemd oneshot service (not TLP) — auto-cpufreq already manages CPU governors, TLP conflicts
2. **wlsunset**: Hyprland exec-once (not HM service) per user preference, with pkill toggle keybind
3. **VPN**: NetworkManager plugins (not standalone wg-quick/openvpn services) for GUI integration
4. **Monitor profiling**: kanshi via HM service (Hyprland monitor rules are static; kanshi reacts to hotplug dynamically)
5. **Screenshot pipeline**: Extend existing grim+slurp with satty for annotations, separate wf-recorder for recording

---

## Phase 0: Validation Strategy

### Validation Commands

| Command | Purpose |
|---------|---------|
| `nix flake check` | Evaluates all configs + runs assertion checks |
| `nix flake check --no-build` | Fast eval-only (assertions fire, no VM tests) |
| `nixos-rebuild build --flake .#thiniel` | Full build validation |
| `sudo nixos-rebuild test --flake .#thiniel` | Apply without switching (live test) |
| `sudo nixos-rebuild switch --flake .#thiniel` | Apply and switch |

### Rollback Path

```bash
# Revert to previous generation
sudo nixos-rebuild switch --rollback
# Or boot into previous generation from systemd-boot menu
```

### Dangerous Changes

| Item | Risk | Mitigation |
|------|------|------------|
| Item 7 (Battery thresholds) | Incorrect sysfs writes | Verify paths exist before writing; thresholds are non-destructive |
| Item 8 (WWAN/ModemManager) | NetworkManager interaction | MM integrates cleanly with NM; test with `mmcli -L` |
| Item 10 (VPN) | Firewall/routing changes | NM plugins handle routing; no firewall changes needed for client |

### Scaffold Step: Create New Assertion Files

Before Phase 1, create the two new assertion file skeletons and register them in `tests/assertions/default.nix`:

**Step S.1**: Create `tests/assertions/thiniel-hardware-invariants.nix` with empty assertions list, guarded by hostname.

**Step S.2**: Create `tests/assertions/thiniel-desktop-apps-invariants.nix` with empty assertions list, guarded by hostname.

**Step S.3**: Add both imports to `tests/assertions/default.nix`.

**Verify**: `nix flake check --no-build` → PASS (empty assertions are valid)

**Commit**: `chore(tests): scaffold thiniel hardware and desktop-apps assertion files`

---

## Phase 1: Everyday — Items 1-5

---

### Item 1: Bluetooth

**Files**: `hosts/thiniel/default.nix`, `tests/assertions/thiniel-hardware-invariants.nix`, `tests/assertions/thiniel-impermanence-invariants.nix`

`bluetuith` is already installed; PipeWire bluetooth audio works automatically when `hardware.bluetooth.enable = true` (wireplumber handles codec negotiation).

#### Cycle 1.1 — Bluetooth enabled

**RED**: Add assertion to `tests/assertions/thiniel-hardware-invariants.nix`:
```nix
{
  assertion = config.hardware.bluetooth.enable;
  message = "thiniel: hardware.bluetooth.enable must be true for bluetooth support";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `hosts/thiniel/default.nix`:
```nix
hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = false;
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable bluetooth hardware support`

#### Cycle 1.2 — Bluetooth persistence

**RED**: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
```nix
{
  assertion = hasDir "/var/lib/bluetooth";
  message = "thiniel: /var/lib/bluetooth must be persisted for bluetooth pairings";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Uncomment `"/var/lib/bluetooth"` in `hosts/thiniel/default.nix` `environment.persistence."/persist/system".directories`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): persist bluetooth pairings in impermanence`

---

### Item 2: PDF Viewer — Zathura

**Files**: `home/dan/features/productivity/zathura.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-desktop-apps-invariants.nix`, `home/dan/features/linux/hyprland.nix`

[MCP] Verify `stylix.targets.zathura` exists during implementation.

#### Cycle 2.1 — Zathura enabled

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion = config.home-manager.users.dan.programs.zathura.enable;
  message = "thiniel: programs.zathura.enable must be true for PDF viewing";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Create `home/dan/features/productivity/zathura.nix`:
```nix
{ ... }:
{
  stylix.targets.zathura.enable = true;
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
    };
  };
}
```
Add import `./features/productivity/zathura.nix` to `home/dan/thiniel.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add zathura PDF viewer with Stylix theming`

#### Cycle 2.2 — PDF MIME type default

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion =
    let
      hmMime = config.home-manager.users.dan.xdg.mimeApps.defaultApplications;
    in
    (hmMime ? "application/pdf")
    && builtins.elem "org.pwmt.zathura.desktop" hmMime."application/pdf";
  message = "thiniel: application/pdf must default to Zathura";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/productivity/zathura.nix`:
```nix
xdg.mimeApps = {
  enable = true;
  defaultApplications = {
    "application/pdf" = [ "org.pwmt.zathura.desktop" ];
  };
};
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): set zathura as default PDF viewer via xdg.mimeApps`

#### Cycle 2.3 — Zathura Hyprland window rules

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      rules = config.home-manager.users.dan.wayland.windowManager.hyprland.settings.windowrule;
    in
    builtins.any (r: (r.name or "") == "zathura-default") rules;
  message = "thiniel: Hyprland must have a windowrule named zathura-default";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/productivity/zathura.nix` (contributes to Hyprland settings via module merge):
```nix
wayland.windowManager.hyprland.settings.windowrule = [
  {
    name = "zathura-default";
    "match:class" = "^org.pwmt.zathura$";
    # Add desired rules, e.g., opacity or specific workspace
  }
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Hyprland window rules for Zathura`

---

### Item 3: Media Player — MPV

**Files**: `home/dan/features/productivity/mpv.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-desktop-apps-invariants.nix`, `home/dan/features/linux/hyprland.nix`

[MCP] Verify `stylix.targets.mpv` exists during implementation.

#### Cycle 3.1 — MPV enabled with hardware decoding

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion = config.home-manager.users.dan.programs.mpv.enable;
  message = "thiniel: programs.mpv.enable must be true for media playback";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Create `home/dan/features/productivity/mpv.nix`:
```nix
{ ... }:
{
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
      vo = "gpu";
      gpu-context = "wayland";
    };
  };
}
```
Add import `./features/productivity/mpv.nix` to `home/dan/thiniel.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add mpv media player with hardware decoding`

#### Cycle 3.2 — Video/audio MIME type defaults

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion =
    let
      hmMime = config.home-manager.users.dan.xdg.mimeApps.defaultApplications;
    in
    (hmMime ? "video/mp4")
    && builtins.elem "mpv.desktop" hmMime."video/mp4";
  message = "thiniel: video/mp4 must default to mpv";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/productivity/mpv.nix`:
```nix
xdg.mimeApps = {
  enable = true;
  defaultApplications = {
    "video/mp4" = [ "mpv.desktop" ];
    "video/x-matroska" = [ "mpv.desktop" ];
    "video/webm" = [ "mpv.desktop" ];
    "audio/mpeg" = [ "mpv.desktop" ];
    "audio/flac" = [ "mpv.desktop" ];
    "audio/ogg" = [ "mpv.desktop" ];
  };
};
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): set mpv as default for video and audio MIME types`

#### Cycle 3.3 — MPV Hyprland window rules for float and PiP

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      rules = config.home-manager.users.dan.wayland.windowManager.hyprland.settings.windowrule;
    in
    builtins.any (r: (r.name or "") == "mpv-pip") rules;
  message = "thiniel: Hyprland must have mpv-pip windowrule for picture-in-picture";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/productivity/mpv.nix`:
```nix
wayland.windowManager.hyprland.settings.windowrule = [
  {
    name = "mpv-float";
    float = true;
    "match:class" = "^mpv$";
    "match:title" = "^(?!.*(mpv)).*$";  # float file dialogs
  }
  {
    name = "mpv-pip";
    float = true;
    pin = true;
    size = "25% 25%";
    move = "75% 75%";
    "match:class" = "^mpv$";
    "match:title" = "^mpv.*pip.*$";
  }
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Hyprland window rules for mpv float and PiP`

---

### Item 4: Automatic Night Light — wlsunset

**Files**: `home/dan/features/linux/wlsunset.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-rice-invariants.nix`

Uses Hyprland exec-once (not HM systemd service) per user preference. Toggle via pkill pattern.

#### Cycle 4.1 — wlsunset in Hyprland exec-once

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      execOnce = lib.toList (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.exec-once or []);
    in
    builtins.any (cmd: builtins.match ".*wlsunset.*" cmd != null) execOnce;
  message = "thiniel: Hyprland exec-once must include wlsunset for night light";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Create `home/dan/features/linux/wlsunset.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.wlsunset ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "wlsunset -l 50.85 -L 4.35"
    ];
  };
}
```
Add import `./features/linux/wlsunset.nix` to `home/dan/thiniel.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add wlsunset night light via Hyprland exec-once`

#### Cycle 4.2 — wlsunset toggle keybind

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      allBinds = lib.toList (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.bind or []);
    in
    builtins.any (b: builtins.match ".*wlsunset.*" b != null) allBinds;
  message = "thiniel: Hyprland bind must include wlsunset toggle keybind";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/linux/wlsunset.nix`:
```nix
wayland.windowManager.hyprland.settings.bind = [
  "$mainMod SHIFT, N, exec, pkill wlsunset || wlsunset -l 50.85 -L 4.35"
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add SUPER+SHIFT+N keybind to toggle wlsunset`

---

### Item 5: Printer — CUPS + Avahi

**Files**: `hosts/thiniel/default.nix`, `tests/assertions/thiniel-services-invariants.nix`, `tests/assertions/thiniel-impermanence-invariants.nix`

#### Cycle 5.1 — CUPS printing enabled

**RED**: Add assertion to `tests/assertions/thiniel-services-invariants.nix`:
```nix
{
  assertion = config.services.printing.enable;
  message = "thiniel: services.printing.enable must be true for CUPS printing";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Uncomment `services.printing.enable = true;` in `hosts/thiniel/default.nix` (line ~214).

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable CUPS printing service`

#### Cycle 5.2 — Avahi network printer discovery

**RED**: Add assertion to `tests/assertions/thiniel-services-invariants.nix`:
```nix
{
  assertion = config.services.avahi.enable && config.services.avahi.nssmdns4;
  message = "thiniel: Avahi must be enabled with nssmdns4 for network printer auto-discovery";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `hosts/thiniel/default.nix`:
```nix
services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
};
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable Avahi for network printer auto-discovery`

#### Cycle 5.3 — CUPS persistence

**RED**: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
```nix
{
  assertion = hasDir "/var/lib/cups";
  message = "thiniel: /var/lib/cups must be persisted for printer configurations";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add `"/var/lib/cups"` to `environment.persistence."/persist/system".directories` in `hosts/thiniel/default.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): persist CUPS state in impermanence`

---

## Phase 2: Hardware — Items 6-9

---

### Item 6: Firmware Updates — fwupd

**Files**: `hosts/thiniel/default.nix`, `tests/assertions/thiniel-hardware-invariants.nix`, `tests/assertions/thiniel-impermanence-invariants.nix`

#### Cycle 6.1 — fwupd enabled

**RED**: Add assertion to `tests/assertions/thiniel-hardware-invariants.nix`:
```nix
{
  assertion = config.services.fwupd.enable;
  message = "thiniel: services.fwupd.enable must be true for firmware updates";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `hosts/thiniel/default.nix`:
```nix
services.fwupd.enable = true;
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable fwupd firmware update service`

#### Cycle 6.2 — fwupd persistence

**RED**: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
```nix
{
  assertion = hasDir "/var/lib/fwupd";
  message = "thiniel: /var/lib/fwupd must be persisted for firmware update state";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add `"/var/lib/fwupd"` to `environment.persistence."/persist/system".directories` in `hosts/thiniel/default.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): persist fwupd state in impermanence`

---

### Item 7: Battery Charge Thresholds

**Files**: `hosts/thiniel/default.nix`, `tests/assertions/thiniel-hardware-invariants.nix`

**Design decision**: auto-cpufreq already manages CPU governors. TLP conflicts with auto-cpufreq. Use a systemd oneshot service to write thresholds directly to `/sys/class/power_supply/BAT0/charge_control_{start,stop}_threshold` via the `thinkpad_acpi` kernel module (already loaded by `nixos-hardware.nixosModules.lenovo-thinkpad-x270`).

[MCP] Verify during implementation: `nixos-hardware.nixosModules.lenovo-thinkpad-x270` loads `thinkpad_acpi`.

#### Cycle 7.1 — Battery threshold systemd service

**RED**: Add assertion to `tests/assertions/thiniel-hardware-invariants.nix`:
```nix
{
  assertion = config.systemd.services ? battery-charge-threshold;
  message = "thiniel: systemd.services.battery-charge-threshold must exist for ThinkPad battery longevity";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `hosts/thiniel/default.nix`:
```nix
systemd.services.battery-charge-threshold = {
  description = "Set ThinkPad battery charge thresholds (60/80)";
  after = [ "multi-user.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
  script = ''
    if [ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
      echo 60 > /sys/class/power_supply/BAT0/charge_control_start_threshold
      echo 80 > /sys/class/power_supply/BAT0/charge_control_stop_threshold
    fi
  '';
};
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add battery charge thresholds 60/80 via systemd oneshot`

#### Cycle 7.2 — Battery threshold values assertion

**RED**: Add assertion to `tests/assertions/thiniel-hardware-invariants.nix`:
```nix
{
  assertion =
    let
      script = config.systemd.services.battery-charge-threshold.script;
    in
    (builtins.match ".*echo 60.*start_threshold.*" script != null)
    && (builtins.match ".*echo 80.*stop_threshold.*" script != null);
  message = "thiniel: battery thresholds must be start=60 stop=80";
}
```
**Verify**: `nix flake check --no-build` → PASS (already implemented in 7.1)

> Note: This cycle validates the threshold values are correct. Since 7.1 already sets the correct values, this assertion passes immediately — it serves as a regression guard.

**Commit**: `test(thiniel): add regression assertion for battery threshold values`

---

### Item 8: WWAN Modem

**Files**: `hosts/thiniel/default.nix`, `tests/assertions/thiniel-hardware-invariants.nix`, `tests/assertions/thiniel-impermanence-invariants.nix`

ModemManager integrates with NetworkManager automatically.

#### Cycle 8.1 — ModemManager enabled

**RED**: Add assertion to `tests/assertions/thiniel-hardware-invariants.nix`:
```nix
{
  assertion = config.networking.modemmanager.enable;
  message = "thiniel: networking.modemmanager.enable must be true for WWAN modem support";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `hosts/thiniel/default.nix`:
```nix
networking.modemmanager.enable = true;
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable ModemManager for WWAN modem`

#### Cycle 8.2 — ModemManager persistence

**RED**: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
```nix
{
  assertion = hasDir "/var/lib/ModemManager";
  message = "thiniel: /var/lib/ModemManager must be persisted for modem state";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add `"/var/lib/ModemManager"` to `environment.persistence."/persist/system".directories` in `hosts/thiniel/default.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): persist ModemManager state in impermanence`

---

### Item 9: Touchpad Gestures

**Files**: `home/dan/features/linux/hyprland.nix`, `tests/assertions/thiniel-rice-invariants.nix`

Hyprland-native gestures: workspace swipe with 3-finger gesture.

#### Cycle 9.1 — Workspace swipe gesture enabled

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      gestures = config.home-manager.users.dan.wayland.windowManager.hyprland.settings.gestures or {};
    in
    gestures.workspace_swipe or false;
  message = "thiniel: Hyprland gestures.workspace_swipe must be enabled for touchpad workspace switching";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/linux/hyprland.nix` inside `settings`:
```nix
gestures = {
  workspace_swipe = true;
  workspace_swipe_fingers = 3;
  workspace_swipe_distance = 300;
  workspace_swipe_cancel_ratio = 0.5;
};
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable 3-finger touchpad swipe for workspace switching`

---

## Phase 3: Workflow — Items 10-15

---

### Item 10: VPN — WireGuard + OpenVPN

**Files**: `hosts/thiniel/default.nix`, `tests/assertions/thiniel-services-invariants.nix`, `tests/assertions/thiniel-impermanence-invariants.nix`

Use NetworkManager plugins for GUI integration. WireGuard kernel module is available by default. Leave Mullvad commented out with a TODO marker.

#### Cycle 10.1 — NetworkManager OpenVPN plugin

**RED**: Add assertion to `tests/assertions/thiniel-services-invariants.nix`:
```nix
{
  assertion =
    let
      pluginNames = builtins.map (p: p.pname or p.name or "") config.networking.networkmanager.plugins;
    in
    builtins.any (n: builtins.match ".*openvpn.*" n != null) pluginNames;
  message = "thiniel: NetworkManager must have OpenVPN plugin installed";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `hosts/thiniel/default.nix`:
```nix
networking.networkmanager.plugins = with pkgs; [
  networkmanager-openvpn
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add NetworkManager OpenVPN plugin for VPN support`

#### Cycle 10.2 — VPN persistence

**RED**: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
```nix
{
  assertion = hasDir "/etc/NetworkManager/system-connections";
  message = "thiniel: /etc/NetworkManager/system-connections must be persisted for VPN configs";
}
```
**Verify**: `nix flake check --no-build` → PASS (already persisted!)

> Note: NM system-connections is already in impermanence (line 136 of `hosts/thiniel/default.nix`). This assertion serves as a regression guard. VPN profiles stored via NM are automatically persisted.

**Commit**: `test(thiniel): add regression assertion for VPN config persistence`

#### Cycle 10.3 — Mullvad TODO comment

**GREEN**: Add a commented block to `hosts/thiniel/default.nix`:
```nix
# TODO: Mullvad VPN — enable when subscription is active
# services.mullvad-vpn.enable = true;
# Impermanence entries needed:
#   "/etc/mullvad-vpn"
#   "/var/cache/mullvad-vpn"
```

**Commit**: `docs(thiniel): add Mullvad VPN TODO placeholder`

---

### Item 11: Backup — TODO Only

**No implementation.** Document as a TODO in this plan.

> **TODO**: Evaluate backup strategy for thiniel. Candidates:
> - `services.borgbackup` for encrypted incremental backups to NAS/cloud
> - `services.restic` for deduplicated backups
> - BorgBase or rsync.net as remote target
> - Backup scope: `/persist` subtree (covers all impermanence state)
> - Exclusions: `.cache/`, `node_modules/`, container images
> - Schedule: daily incremental, weekly pruning
>
> **No TDD cycles — planning only.**

---

### Item 12: Signal + Threema

**Files**: `home/dan/features/productivity/messaging.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-desktop-apps-invariants.nix`, `home/dan/features/linux/impermanence.nix`

Both are Electron apps with Wayland support.

#### Cycle 12.1 — Signal Desktop installed

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion =
    let
      hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
    in
    builtins.elem "signal-desktop" hmPkgNames;
  message = "thiniel: Signal Desktop must be installed for secure messaging";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Create `home/dan/features/productivity/messaging.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    signal-desktop
  ];
}
```
Add import `./features/productivity/messaging.nix` to `home/dan/thiniel.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Signal Desktop for secure messaging`

#### Cycle 12.2 — Threema Desktop installed

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion =
    let
      hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
    in
    builtins.elem "threema-desktop" hmPkgNames;
  message = "thiniel: Threema Desktop must be installed for secure messaging";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add `threema-desktop` to `home.packages` in `home/dan/features/productivity/messaging.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Threema Desktop for secure messaging`

#### Cycle 12.3 — Messaging Hyprland window rules

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      rules = config.home-manager.users.dan.wayland.windowManager.hyprland.settings.windowrule;
    in
    builtins.any (r: (r.name or "") == "signal-ws") rules;
  message = "thiniel: Hyprland must have Signal Desktop window rules";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/productivity/messaging.nix`:
```nix
wayland.windowManager.hyprland.settings.windowrule = [
  {
    name = "signal-ws";
    "match:class" = "^Signal$";
    # Assign to workspace or set other rules as desired
  }
  {
    name = "threema-ws";
    "match:class" = "^Threema$";
  }
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Hyprland window rules for Signal and Threema`

#### Cycle 12.4 — Messaging app state persistence

**RED**: Add assertion to `tests/assertions/thiniel-impermanence-invariants.nix`:
```nix
{
  assertion = hmHasDir ".config/Signal";
  message = "thiniel: .config/Signal must be persisted for Signal Desktop state";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/linux/impermanence.nix` `home.persistence."/persist".directories`:
```nix
".config/Signal"
".config/Threema"
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): persist Signal and Threema app state in impermanence`

---

### Item 13: Monitor Profiling — kanshi

**Files**: `home/dan/features/linux/kanshi.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-rice-invariants.nix`

kanshi dynamically reconfigures outputs on hotplug. Hyprland's static `monitor` rules provide defaults; kanshi handles per-profile overrides for docking.

#### Cycle 13.1 — kanshi service enabled

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion = config.home-manager.users.dan.services.kanshi.enable;
  message = "thiniel: services.kanshi.enable must be true for dynamic monitor profiling";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Create `home/dan/features/linux/kanshi.nix`:
```nix
{ ... }:
{
  services.kanshi = {
    enable = true;
  };
}
```
Add import `./features/linux/kanshi.nix` to `home/dan/thiniel.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): enable kanshi for dynamic monitor profiling`

#### Cycle 13.2 — kanshi profiles for docking

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      profiles = config.home-manager.users.dan.services.kanshi.profiles;
    in
    profiles ? undocked;
  message = "thiniel: kanshi must have an undocked profile as baseline";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add profiles to `home/dan/features/linux/kanshi.nix`:
```nix
services.kanshi.profiles = {
  undocked = {
    outputs = [
      {
        criteria = "eDP-1";
        status = "enable";
        mode = "1920x1080";
        position = "0,0";
        scale = 1.0;
      }
    ];
  };
  # Additional profiles to be added as docking scenarios are identified
  # docked-hdmi = {
  #   outputs = [
  #     { criteria = "eDP-1"; status = "enable"; position = "0,0"; }
  #     { criteria = "HDMI-A-1"; status = "enable"; position = "1920,0"; }
  #   ];
  # };
};
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add kanshi undocked profile as baseline`

---

### Item 14: Screenshot Annotations — Satty

**Files**: `home/dan/features/linux/screenshot.nix`, `home/dan/thiniel.nix`, `tests/assertions/thiniel-desktop-apps-invariants.nix`, `tests/assertions/thiniel-rice-invariants.nix`

Extends existing grim+slurp pipeline with satty for annotation.

#### Cycle 14.1 — Satty package installed

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion =
    let
      hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
    in
    builtins.elem "satty" hmPkgNames;
  message = "thiniel: satty must be installed for screenshot annotation";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Create `home/dan/features/linux/screenshot.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    satty
  ];
}
```
Add import `./features/linux/screenshot.nix` to `home/dan/thiniel.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add satty for screenshot annotation`

#### Cycle 14.2 — Annotated screenshot keybinds

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      allBinds = lib.toList (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.bind or []);
    in
    builtins.any (b: builtins.match ".*satty.*" b != null) allBinds;
  message = "thiniel: Hyprland bind must include satty annotation keybind";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/linux/screenshot.nix`:
```nix
wayland.windowManager.hyprland.settings.bind = [
  # Annotated region screenshot
  "$mainMod SHIFT, Print, exec, grim -g \"$(slurp)\" - | satty --filename -"
  # Annotated fullscreen screenshot
  "$mainMod ALT, Print, exec, grim - | satty --filename -"
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Hyprland keybinds for annotated screenshots via satty`

---

### Item 15: Screen Recording — wf-recorder

**Files**: `home/dan/features/linux/screenshot.nix` (same file as item 14), `tests/assertions/thiniel-desktop-apps-invariants.nix`, `tests/assertions/thiniel-rice-invariants.nix`

#### Cycle 15.1 — wf-recorder package installed

**RED**: Add assertion to `tests/assertions/thiniel-desktop-apps-invariants.nix`:
```nix
{
  assertion =
    let
      hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home-manager.users.dan.home.packages;
    in
    builtins.elem "wf-recorder" hmPkgNames;
  message = "thiniel: wf-recorder must be installed for screen recording";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add `wf-recorder` to `home.packages` in `home/dan/features/linux/screenshot.nix`.

**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add wf-recorder for Wayland screen recording`

#### Cycle 15.2 — Screen recording keybinds

**RED**: Add assertion to `tests/assertions/thiniel-rice-invariants.nix`:
```nix
{
  assertion =
    let
      allBinds = lib.toList (config.home-manager.users.dan.wayland.windowManager.hyprland.settings.bind or []);
    in
    builtins.any (b: builtins.match ".*wf-recorder.*" b != null) allBinds;
  message = "thiniel: Hyprland bind must include wf-recorder keybinds for screen recording";
}
```
**Verify**: `nix flake check --no-build` → FAIL

**GREEN**: Add to `home/dan/features/linux/screenshot.nix`:
```nix
wayland.windowManager.hyprland.settings.bind = [
  # Toggle fullscreen recording (stop if running, start if not)
  "$mainMod, F9, exec, pkill -INT wf-recorder || wf-recorder -f ~/Videos/rec-$(date +%s).mp4"
  # Start region recording (stop with SUPER+F9)
  "$mainMod SHIFT, F9, exec, wf-recorder -g \"$(slurp)\" -f ~/Videos/rec-$(date +%s).mp4"
];
```
**Verify**: `nix flake check --no-build` → PASS

**Commit**: `feat(thiniel): add Hyprland keybinds for screen recording toggle`

---

## Summary

### Total TDD Cycles: 30

| Phase | Item | Cycles | Description |
|-------|------|--------|-------------|
| S | Scaffold | 1 | Create assertion file skeletons |
| 1 | Bluetooth | 2 | Enable + persist |
| 1 | Zathura | 3 | Enable + MIME + windowrule |
| 1 | MPV | 3 | Enable + MIME + windowrule |
| 1 | wlsunset | 2 | exec-once + toggle keybind |
| 1 | Printer | 3 | CUPS + Avahi + persist |
| 2 | fwupd | 2 | Enable + persist |
| 2 | Battery | 2 | Systemd service + values guard |
| 2 | WWAN | 2 | MM enable + persist |
| 2 | Gestures | 1 | Hyprland native workspace_swipe |
| 3 | VPN | 3 | NM plugin + persist guard + Mullvad TODO |
| 3 | Backup | 0 | Documentation TODO only |
| 3 | Messaging | 4 | Signal + Threema + windowrules + persist |
| 3 | Monitors | 2 | kanshi enable + undocked profile |
| 3 | Screenshots | 2 | Satty + keybinds |
| 3 | Recording | 2 | wf-recorder + keybinds |

### Items Needing MCP Verification During Implementation

- Item 2 (Zathura): Verify `stylix.targets.zathura` exists
- Item 3 (MPV): Verify `stylix.targets.mpv` exists
- Item 7 (Battery): Verify `nixos-hardware.nixosModules.lenovo-thinkpad-x270` loads `thinkpad_acpi`
- Item 10 (VPN): Verify `networkmanager-openvpn` package attribute path
- Item 12 (Messaging): Verify `signal-desktop` and `threema-desktop` exact package attribute names

### Keybind Reference

| Keybind | Action | Item |
|---------|--------|------|
| `SUPER+SHIFT+N` | Toggle wlsunset night light | 4 |
| `SUPER+Print` | Region screenshot → clipboard (existing) | — |
| `SUPER+SHIFT+Print` | Region screenshot → satty annotation | 14 |
| `SUPER+ALT+Print` | Fullscreen screenshot → satty annotation | 14 |
| `SUPER+F9` | Toggle fullscreen screen recording | 15 |
| `SUPER+SHIFT+F9` | Start region screen recording | 15 |

### New Feature Module Import Order for `home/dan/thiniel.nix`

```nix
./features/linux/kanshi.nix
./features/linux/screenshot.nix
./features/linux/wlsunset.nix
./features/productivity/messaging.nix
./features/productivity/mpv.nix
./features/productivity/zathura.nix
```

---

## Current Status

- **Plan**: CREATED
- **Phase S (Scaffold)**: PENDING
- **Phase 1 (Everyday)**: PENDING
- **Phase 2 (Hardware)**: PENDING
- **Phase 3 (Workflow)**: PENDING

## Completion Log

*(Updated as phases are completed)*

## Lessons Learned

### 1. nixos-hardware modules can silently enable conflicting services

`nixos-hardware.nixosModules.lenovo-thinkpad-x270` implicitly enables TLP, which directly conflicts with auto-cpufreq. Without the TDD regression-guard assertion (`services.tlp.enable == false`), this conflict would have gone undetected until runtime.

**Action**: When using `nixos-hardware` modules, always check which services are implicitly enabled. Add explicit `= false` overrides and regression-guard assertions for known conflicts.

### 2. TDD commit granularity must be squashed before merge

Strict TDD with separate Red/Green commits produced ~55 commits for 15 features. This granularity is useful during development but too noisy for the Git history.

**Action**: TDD cycles are committed separately during work, but squashed per feature before merging into the main branch. Each feature = 1 commit containing both test and implementation.

### 3. Impermanence completeness requires systematic checking

`~/Videos` was not persisted — wf-recorder recordings would have been lost on reboot. The review caught this, but it should have been identified during feature design.

**Action**: For every new feature that writes files, immediately ask: *"Where does this tool write? Is that path persisted?"* Checklist:
- System state → `/var/lib/<service>` → `environment.persistence`
- User config → `.config/<app>` → HM `home.persistence`
- User data → `~/Videos`, `~/Documents` etc. → HM `home.persistence`

### 4. Count-based unit tests are fragile

Existing unit tests in `tests/unit/hm-linux-modules-test.nix` count Hyprland binds, windowrules, and impermanence directories. Adding new entries requires updating these counts manually. This is a maintenance burden.

**Action**: Consider refactoring count-based tests to check for existence of specific entries rather than total counts.

### 5. Subtask delegation requires explicit value pinning

A subtask changed wlsunset coordinates from Brussels to Berlin without being asked. Subtasks can "hallucinate" values when context is not explicit enough.

**Action**: When delegating subtasks, explicitly state all concrete values that must not be changed. Do not rely on the subtask knowing the overall context.

### 6. Batch similar features after pattern is established

The last 7 features were batched into a single subtask — instead of 14 individual subtasks (7× Red + 7× Green). This was significantly more efficient without sacrificing TDD quality. The initial atomic approach (1 subtask = 1 assertion) was instructive for the first features but unnecessarily granular once the pattern was established.

**Action**: Use atomic subtask delegation for the first 2–3 features of a new pattern. Then batch similar features into one subtask once the pattern is proven.

### 7. Code review after implementation finds real bugs

Confirmed findings from the review phase:
- Governor typo `powersafe` → `powersave` (runtime error on battery)
- TLP conflict from nixos-hardware module (service conflict)
- Unpersisted `~/Videos` directory (data loss on reboot)
- Stale unit test counts (CI failure)

**Action**: The review phase is not a formality — it caught 4 bugs with real runtime impact. Always run a review subtask before completing a feature branch.
