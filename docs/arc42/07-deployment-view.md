# 7. Deployment View

Mapping of the declared configurations to infrastructure. The repository
declares the host configurations; it does not record live deployment state. All
addresses below are documentation-range defaults from `hosts/<host>/options.nix`
or values from the `private` flake input, not values verified in this
repository.

## Infrastructure level 1

```svg
<svg viewBox="0 0 920 420" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Declared fleet topology: owner site and netcup cloud">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="var(--muted)"/>
    </marker>
  </defs>

  <rect x="12" y="12" width="470" height="396" rx="10" fill="none" stroke="var(--border)" stroke-dasharray="4 4"/>
  <text x="26" y="36" font-size="14" fill="var(--fg)">Owner site (one LAN, addresses from the private input)</text>

  <rect x="34" y="56" width="200" height="96" rx="8" fill="none" stroke="var(--border)"/>
  <text x="46" y="82" font-size="14" fill="var(--fg)">J6G6Y9JK7L</text>
  <text x="46" y="102" font-size="12" fill="var(--muted)">aarch64-darwin</text>
  <text x="46" y="120" font-size="12" fill="var(--muted)">nix-darwin + homebrew</text>
  <text x="46" y="138" font-size="12" fill="var(--muted)">work MacBook</text>

  <rect x="34" y="172" width="200" height="96" rx="8" fill="none" stroke="var(--border)"/>
  <text x="46" y="198" font-size="14" fill="var(--fg)">thiniel</text>
  <text x="46" y="218" font-size="12" fill="var(--muted)">x86_64-linux</text>
  <text x="46" y="236" font-size="12" fill="var(--muted)">ThinkPad X270</text>
  <text x="46" y="254" font-size="12" fill="var(--muted)">impermanent root</text>

  <rect x="262" y="56" width="200" height="96" rx="8" fill="none" stroke="var(--border)"/>
  <text x="274" y="82" font-size="14" fill="var(--fg)">adlerkopf</text>
  <text x="274" y="102" font-size="12" fill="var(--muted)">x86_64-linux</text>
  <text x="274" y="120" font-size="12" fill="var(--muted)">home server</text>
  <text x="274" y="138" font-size="12" fill="var(--muted)">LUKS + btrfs + TPM2</text>

  <rect x="262" y="172" width="200" height="96" rx="8" fill="none" stroke="var(--border)"/>
  <text x="274" y="198" font-size="14" fill="var(--fg)">adlerkopf.vmMode</text>
  <text x="274" y="218" font-size="12" fill="var(--muted)">declared vmVariant block</text>
  <text x="274" y="236" font-size="12" fill="var(--muted)">relaxes hardware assertions</text>
  <text x="274" y="254" font-size="12" fill="var(--muted)">no flake attribute materializes it</text>

  <rect x="34" y="288" width="428" height="96" rx="8" fill="none" stroke="var(--border)"/>
  <text x="46" y="314" font-size="14" fill="var(--fg)">nixos-vm-minimal</text>
  <text x="46" y="334" font-size="12" fill="var(--muted)">aarch64-linux guest (UTM/QEMU), LUKS root, systemd-boot</text>
  <text x="46" y="352" font-size="12" fill="var(--muted)">also the target of scripts/deploy-vm.sh (default 192.168.64.2)</text>
  <text x="46" y="370" font-size="12" fill="var(--muted)">hosts/nixos-vm-minimal and templates/host are the provisioning paths</text>

  <rect x="520" y="12" width="388" height="252" rx="10" fill="none" stroke="var(--border)" stroke-dasharray="4 4"/>
  <text x="534" y="36" font-size="14" fill="var(--fg)">netcup cloud</text>

  <rect x="544" y="56" width="340" height="104" rx="8" fill="none" stroke="var(--border)"/>
  <text x="558" y="82" font-size="14" fill="var(--fg)">cupix001 (netcup VPS, x86_64-linux)</text>
  <text x="558" y="104" font-size="12" fill="var(--muted)">declared skeleton: hostName, firewall on,</text>
  <text x="558" y="122" font-size="12" fill="var(--muted)">sops, disko; no services, no VPN, no ingress</text>
  <text x="558" y="144" font-size="12" fill="var(--muted)">resolve the actual values in the private input</text>

  <rect x="544" y="176" width="340" height="72" rx="8" fill="none" stroke="var(--border)"/>
  <text x="558" y="202" font-size="14" fill="var(--fg)">netcup SCP account firewall</text>
  <text x="558" y="224" font-size="12" fill="var(--muted)">managed from thiniel by scripts/netcup_firewall.py</text>
  <text x="558" y="242" font-size="12" fill="var(--muted)">HTTP API, not the host's own ruleset</text>

  <rect x="520" y="288" width="388" height="96" rx="8" fill="none" stroke="var(--border)"/>
  <text x="534" y="314" font-size="14" fill="var(--fg)">Build-time, not runtime</text>
  <text x="534" y="336" font-size="12" fill="var(--muted)">the owner's workstation builds the closure; Nix copies it</text>
  <text x="534" y="354" font-size="12" fill="var(--muted)">SSH to fleet nodes; TPM2/SSH bootstrap documented in</text>
  <text x="534" y="372" font-size="12" fill="var(--muted)">docs/ADLERKOPF-DEPLOY-RUNBOOK.md</text>

  <path d="M234 104 L262 104" fill="none" stroke="var(--muted)" marker-end="url(#arrow)"/>
  <path d="M234 216 L262 216" fill="none" stroke="var(--muted)" marker-end="url(#arrow)"/>
</svg>
```

| Node / Environment | Declared role | Provisioning |
|---|---|---|
| `J6G6Y9JK7L` | Work macOS workstation (owner's primary development host) | `darwin-rebuild switch --flake .#J6G6Y9JK7L` |
| `thiniel` | Owner's Linux laptop | `nixos-rebuild switch --flake .#thiniel`; `nixos-hardware` X270 module |
| `adlerkopf` | Home server | `nixos-anywhere` first install (`docs/ADLERKOPF-DEPLOY-RUNBOOK.md`), then `nixos-rebuild --target-host` |
| `adlerkopf` vmVariant (`adlerkopf.vmMode = true`) | A declared VM variant that relaxes the hardware assertions (no LUKS/TPM2/lanzaboote) | **Not materialized**: no flake attribute builds it, and the `integration-adlerkopf` check boots a synthetic machine with the same services instead |
| `nixos-vm-minimal` | Minimal aarch64 VM (test and provisioning template target) | `disko` on `/dev/vda`, LUKS root; `scripts/deploy-vm.sh` |
| `cupix001` | netcup KVM VPS, intended edge gateway | `disko` on `/dev/vda`; values from the `private` flake input |
| netcup SCP account firewall | External firewall state for the VPS | `scripts/netcup_firewall.py` run from thiniel inside `nix develop` |
| Colmena hive | Declared fleet-deployment path | **Empty** — no node is registered |

## Infrastructure level 2

### `adlerkopf` (home server)

| Property | Value (declared) |
|---|---|
| Hardware / VM | Lenovo ThinkCentre M720q per the plan set; `hosts/adlerkopf/hardware.nix` is generated for that machine |
| Disk layout | `disko`: GPT on `/dev/nvme0n1` → ESP 1024M (vfat) + LUKS `cryptroot` → btrfs with `@root`, `@root-blank`, `@persist`, `@nix`, `@log`, `@swap` |
| Boot | `lanzaboote` Secure Boot (systemd-boot force-disabled, UKI limit 5); TPM2 auto-unlock (`tpm2-device=auto`) with passphrase fallback |
| State model | Initrd rollback service recreates `@root` from `@root-blank`; persistent paths declared in `hosts/adlerkopf/impermanence.nix` |
| Services | `openssh` (key-only), `caddy` (custom build with the netcup DNS plugin, no virtual hosts), `adguardhome` (declarative settings, `mutableSettings = false`), networkd static address, nftables firewall |
| Secrets | `hosts/adlerkopf/secrets.yaml`; age key from the SSH host key under `/persist/system` |
| Network (defaults) | Documentation-range defaults: static `192.0.2.10/24` on `eno1`, gateway `192.0.2.1`, DNS `1.1.1.1`/`9.9.9.9`; the real values come from the `private` flake input |
| Build dependency | The `private` flake input; the public default is `private-stub/`, so the host evaluates without private access |

### `thiniel` (owner's laptop)

| Property | Value (declared) |
|---|---|
| Hardware | ThinkPad X270 (`nixos-hardware` module), Intel microcode, btrfs root subvolume `root` on `/dev/root_vg/root` (LVM; no LUKS — the OPAL SED provides full-disk encryption) |
| Boot | systemd-boot; systemd initrd with the root-wipe `rollback` service |
| State model | btrfs root subvolume (`root`) recreated on boot from the same LVM volume; `mySystem.persistence` + per-host persistence list |
| Services | greetd/tuigreet → Hyprland, pipewire, NetworkManager, avahi, openssh, fwupd, gnome-keyring, gvfs, btrfs auto-scrub, auto-cpufreq, podman + one OCI container (`qdrant_roo`) |
| Secrets | `hosts/thiniel/secrets.yaml`; age key file `/var/lib/sops-nix/key.txt`, exposed to the user session via `mkOutOfStoreSymlink` |
| Desktop | `stylix` One Light, Hyprland (unstable), waybar, mako, fuzzel, kanshi, hyprlock, hypridle, wlsunset |
| Sleep policy | Suspend/hibernate disabled (`systemd.sleep` all `no`, `logind` lid ignored) because the root key of the OPAL SED is lost on sleep |

### `cupix001` (netcup VPS)

| Property | Value (declared) |
|---|---|
| Hardware / VM | netcup KVM VPS; `/dev/vda` |
| Disk layout | `disko`: GPT → ESP 512M + btrfs root (no LUKS) with `@root`, `@persist`, `@nix`, `@log`, `@swap` (2G) |
| Networking | **Not declared.** No static address, no interface configuration, no WireGuard, no NAT, no port openings beyond the firewall being enabled |
| Services | **None.** No OpenSSH, no ingress, no DNS, no VPN |
| Secrets | `hosts/cupix001/secrets.yaml` contains a single `placeholder` key; age key from the SSH host key under `/persist` |
| Persistence | `modules/nixos/persistence` is imported but `mySystem.persistence.enable` is never set, so it is inert |
| Ingress / VPN | **Planned, not started.** `cupix001` is the intended edge ingress gateway; the design document `docs/edge-all.md` and the cupix001 plan set describe Caddy forward-auth, derper, WireGuard, CrowdSec, nftables and Authentik. Sequenced after the private-data remediation that must precede a public release ([`docs/plans/private-data-remediation-plan.md`](../plans/private-data-remediation-plan.md), now the change `private-data-remediation`). None of it exists in the working tree. |

### `J6G6Y9JK7L` (work macOS workstation)

| Property | Value (declared) |
|---|---|
| Hardware | Apple Silicon Mac (`aarch64-darwin`) |
| Boot / base | Determinate Nix assumed (`nix.enable = false` disables nix-darwin's own Nix management); `system.stateVersion = 6` |
| System management | `nix-homebrew` with three pinned taps and `mutableTaps = false`; `homebrew.onActivation.cleanup = "zap"`, `autoUpdate = false`, `upgrade = true`; brews `[score-compose]`, casks `[cameracontroller claude claude-code crossover kitty marta]` |
| App linking | `mac-app-util` (system + Home Manager module); `targets.darwin.copyApps.enableChecks = false` because an MDM resets the App Management permission |
| Desktop | `aerospace` tiling window manager, macOS defaults via `targets.darwin.defaults`, `stylix` One Light |
| User | `daniel.kressner`; login shell set to fish by an activation script |
| Secrets | `hosts/J6G6Y9JK7L/secrets.yaml` (14 declared keys); age key file under `~/Library/Application Support/sops/age/` |
