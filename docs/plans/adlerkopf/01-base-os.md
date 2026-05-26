# Phase 1 — Base OS, disko, LUKS+TPM2, impermanence, sops, Caddy skeleton

**Goal**: deployable host that boots without a keyboard, persists `/persist` across reboots,
decrypts sops secrets, and has Caddy installed (no vhosts yet).

## Files to create / modify

```
hosts/adlerkopf/
├── default.nix             # entry point — imports, hostName, sops, stateVersion
├── hardware.nix            # kernel modules, systemd-boot, CPU/NIC settings
├── disko.nix               # GPT → ESP + LUKS2 → btrfs subvolumes
├── networking.nix          # static 192.168.168.15/24, nftables firewall
├── impermanence.nix        # environment.persistence + initrd rollback service
├── tpm2.nix                # boot.initrd.systemd + crypttabExtraOpts
├── caddy.nix               # custom Caddy build with caddy-dns/netcup (no vhosts)
├── options.nix             # typed per-host options (priv.*)
├── private.nix.example     # example values
└── secrets.yaml            # SOPS placeholder

home/dan/adlerkopf.nix                          # HM entrypoint
tests/assertions/adlerkopf-invariants.nix       # eval-time invariants
tests/integration/adlerkopf-test.nix            # VM integration test
.sops.yaml                                      # add &adlerkopf recipient
flake.nix                                       # add nixosConfigurations.adlerkopf
```

## Disk layout (`hosts/adlerkopf/disko.nix`)

```
/dev/nvme0n1  (GPT)
├── ESP        512 MiB  vfat      /boot
└── cryptroot  rest     LUKS2     label=crypt-adlerkopf, allowDiscards=true
    └── btrfs  label=nixos
        ├── @root        →  /            compress=zstd,noatime
        ├── @root-blank  →  (snapshot — created once at install, never mounted)
        ├── @persist     →  /persist     compress=zstd,noatime; neededForBoot=true
        ├── @nix         →  /nix         compress=zstd,noatime; neededForBoot=true
        ├── @log         →  /var/log     compress=zstd,noatime; neededForBoot=true
        └── @swap        →  /swap        swapfile.size=4G  (use zram if RAM ≥ 16G)
```

References:
- subvolume scheme → `hosts/cupix001/disko.nix`
- LUKS-in-disko wrapping → `hosts/nixos-vm-minimal/disko.nix:37-54`

## LUKS2 + TPM2 (`hosts/adlerkopf/tpm2.nix`)

```nix
{
  # Required for TPM2-backed unlock via systemd-cryptsetup in initrd
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
```

**Post-install one-shot** (not declarative — run once after first successful boot):

```fish
sudo systemd-cryptenroll --tpm2-device=auto \
    --tpm2-pcrs=0+2+7 \
    /dev/disk/by-partlabel/cryptroot
```

PCR selection:
- `0` — firmware code (changes on BIOS update → re-enroll required)
- `2` — option ROMs
- `7` — Secure Boot policy (only if Secure Boot is and stays enabled; omit if SB is off → use `0+2`)

The LUKS recovery passphrase (slot 0) is kept untouched. Store it in 1Password before running nixos-anywhere. If TPM binding breaks after a BIOS update, the recovery passphrase allows a one-time boot and re-enrollment.

> **Note**: Secure Boot via lanzaboote is configured in [`01a-secure-boot-plan.md`](01a-secure-boot-plan.md). With SB enabled, use `--tpm2-pcrs=0+2+7`. See that plan for key enrollment and firmware setup steps.

## Impermanence (`hosts/adlerkopf/impermanence.nix`)

### Boot-time rollback

```nix
boot.initrd.systemd.services.rollback = {
  description = "Rollback btrfs @root to blank snapshot";
  wantedBy = [ "initrd.target" ];
  after = [ "systemd-cryptsetup@cryptroot.service" ];
  before = [ "sysroot.mount" ];
  unitConfig.DefaultDependencies = "no";
  serviceConfig.Type = "oneshot";
  script = ''
    mkdir /btrfs_tmp
    mount -t btrfs /dev/mapper/cryptroot /btrfs_tmp
    btrfs subvolume list -o /btrfs_tmp/@root | cut -f9 -d' ' |
      while read sub; do btrfs subvolume delete "/btrfs_tmp/$sub"; done || true
    btrfs subvolume delete /btrfs_tmp/@root
    btrfs subvolume snapshot /btrfs_tmp/@root-blank /btrfs_tmp/@root
    umount /btrfs_tmp
  '';
};
```

Note: `@root-blank` must exist before the first reboot with rollback enabled.
Create it during nixos-anywhere install by running the script once manually, or via a disko `postCreateHook`.

### Persisted paths (Phase 1 baseline — extended in later phases)

```nix
environment.persistence."/persist/system" = {
  hideMounts = true;
  directories = [
    "/var/log"
    "/var/lib/nixos"           # UID/GID map — CRITICAL; loss breaks service ownership
    "/var/lib/systemd/coredump"
    "/var/lib/caddy"
    "/var/lib/private/acme"    # ACME account key + certs
  ];
  files = [
    "/etc/machine-id"
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
  ];
};
```

Paths added per phase:
- Phase 2: `/var/lib/private/AdGuardHome`
- Phase 3: `/var/lib/wireguard`
- Phase 4: `/var/lib/mosquitto`
- Phase 5: `/var/lib/node-red`
- Phase 6: `/var/lib/grafana`

Do **not** persist `/etc/nixos` (flake-managed, always rebuilt from store).

## SSH access (`hosts/adlerkopf/default.nix`)

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };
};

# Extends hosts/common/users/dan.nix (which only sets isNormalUser + wheel group)
users.users.dan = {
  extraGroups = [ "sudo" ];
  shell = pkgs.fish;
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ J6G6Y9JK7L"
    # Add further keys (personal laptop, phone emergency access) as needed
  ];
};

# Required for `nixos-rebuild --use-remote-sudo` to work non-interactively
security.sudo.wheelNeedsPassword = false;
```

Note: the public key above is illustrative. Use the actual key from `~/.ssh/id_ed25519.pub` on the
workstation (J6G6Y9JK7L). The key is public information and safe to commit in the host config.

After Phase 1 is deployed: `ssh dan@192.168.168.15` from the workstation should succeed immediately.

New assertion to add:

```nix
{ assertion = config.services.openssh.enable; message = "adlerkopf: openssh must be enabled"; }
```

## Networking (`hosts/adlerkopf/networking.nix`)

```nix
{
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = "eno1";   # Intel I219-V — verify name after first boot
    address = [ "192.168.168.15/24" ];
    gateway = [ "192.168.168.1" ];
    dns = [ "1.1.1.1" "9.9.9.9" ];   # replaced by 127.0.0.1 in Phase 2
    DHCP = "no";
  };

  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];    # SSH bootstrap; locked down in hardening step
  };

  networking.networkmanager.enable = false;
}
```

## SOPS (`hosts/adlerkopf/default.nix`)

```nix
sops = {
  defaultSopsFile = ./secrets.yaml;
  defaultSopsFormat = "yaml";
  age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
};
```

`.sops.yaml` update needed (add before commit):

```yaml
keys:
  - &adlerkopf age1PLACEHOLDER000000000000000000000000000000000000000000

creation_rules:
  - path_regex: hosts/adlerkopf/secrets\.ya?ml$
    key_groups:
      - age: [*dan_linux, *adlerkopf]
```

Bootstrap procedure (post-install):

```fish
# On adlerkopf after first boot:
ssh-to-age < /persist/etc/ssh/ssh_host_ed25519_key.pub
# → paste resulting age1... into .sops.yaml &adlerkopf line
# On workstation:
sops updatekeys hosts/adlerkopf/secrets.yaml
```

## Caddy skeleton (`hosts/adlerkopf/caddy.nix`)

```nix
{ pkgs, ... }: {
  services.caddy = {
    enable = true;
    # Pin to >= 2.9.2 (CVE GHSA-7r4p-vjf4-gxv4 in netcup plugin)
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/netcup@v1.1.0" ];
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # replace after nix build
    };
  };

  # /var/lib/caddy persisted via impermanence (Phase 1 baseline list)
}
```

No virtualHosts configured yet — first vhost added in Phase 5 (Node-RED).
ACME globals (email, DNS challenge config) configured in Phase 5 when first cert is needed.

## Hardware (`hosts/adlerkopf/hardware.nix`)

```nix
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod"
    "e1000e"    # Intel I219-V NIC — required for initrd network if ever needed
  ];
  boot.kernelModules = [ "kvm-intel" ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = true;
}
```

No `nixos-hardware` named module for M720q. Consider adding
`inputs.nixos-hardware.nixosModules.common-cpu-intel` and
`inputs.nixos-hardware.nixosModules.common-pc-ssd` from `inputs.nixos-hardware`
(already in flake inputs at `flake.nix:41`).

## flake.nix registration

Copy the `cupix001 = nixpkgs.lib.nixosSystem { … }` block (`flake.nix:179-217`), rename to
`adlerkopf`, and point `./hosts/adlerkopf` at the new directory.
Also add an entry to `colmenaHive.nodes` (currently empty at `flake.nix:393-422`).

## Tests (Red → Green)

### Assertions (`tests/assertions/adlerkopf-invariants.nix`)

```nix
lib.mkIf (config.networking.hostName == "adlerkopf") {
  assertions = [
    { assertion = config.networking.firewall.enable; message = "adlerkopf: firewall must be enabled"; }
    { assertion = !config.networking.networkmanager.enable; message = "adlerkopf: NM must be disabled"; }
    { assertion = config.sops.defaultSopsFile == ./secrets.yaml; message = "adlerkopf: sops file must be set"; }
    { assertion = config.disko.devices.disk ? nvme0n1; message = "adlerkopf: disko must target nvme0n1"; }
    { assertion = config.fileSystems."/persist".neededForBoot; message = "adlerkopf: /persist neededForBoot"; }
    { assertion = config.fileSystems."/nix".neededForBoot; message = "adlerkopf: /nix neededForBoot"; }
    { assertion = config.fileSystems."/var/log".neededForBoot; message = "adlerkopf: /var/log neededForBoot"; }
    { assertion = config.services.openssh.settings.PermitRootLogin != "yes"; message = "adlerkopf: root SSH login must be disabled"; }
    { assertion = config.services.caddy.enable; message = "adlerkopf: Caddy must be enabled"; }
  ];
}
```

Wire into `tests/assertions/default.nix` and register in `flake.nix` checks.

### Integration VM test (`tests/integration/adlerkopf-test.nix`)

Uses a stripped-down `adlerkopf-vm` nixosConfiguration (no LUKS) to run in QEMU.
Asserts: sshd active, port 22 listening, port 80 not, Caddy unit active, firewall enabled.
Add as `checks.<linux>.integration-adlerkopf-base` in `flake.nix:382-391`.

## Acceptance criteria

- [ ] `nix flake check --no-build` green (new adlerkopf assertions pass)
- [ ] `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel` succeeds
- [ ] nixos-anywhere provisioning completes (see [deploy-runbook.md](./deploy-runbook.md))
- [ ] Box boots without keyboard interaction (TPM2 unlocks LUKS)
- [ ] `ssh dan@192.168.168.15` with key succeeds
- [ ] `sops decrypt hosts/adlerkopf/secrets.yaml` returns plaintext on the host
- [ ] Reboot: `/` is empty, but `/persist` intact and SSH host key unchanged
- [ ] `systemctl status caddy` → active (no vhosts, just the daemon)
- [ ] Integration VM test green in CI

## Rollback

```fish
# Remote:
nixos-rebuild --rollback --target-host dan@192.168.168.15
# Local (LUKS always openable with recovery passphrase even on total failure):
# boot from USB, mount /persist, rescue data
```

Old Pi remains live throughout Phase 1; no traffic cut over yet.
