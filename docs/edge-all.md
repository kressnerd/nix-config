# NixOS Identity-Aware Edge Ingress Gateway – VPS cupix001 Setup

## Context

You have access to the user's existing NixOS mono-repo (public GitHub, flake-based, hosts/ directory per machine, home-manager as NixOS module, sops-nix with age for secrets). The target is a netcup KVM VPS currently running Debian. The VPS will become a hardened edge reverse proxy for ~4 homelab services.

The hostname for this machine is `cupix001`.

## Goal

Extend the existing NixOS flake mono-repo with a new host configuration `cupix001` that implements a hardened, identity-aware edge ingress gateway. Deploy it to the netcup VPS.

## Architecture

Internet → Caddy (TLS, forward_auth) → WireGuard tunnel → Homelab backends
Internet → derper (STUN UDP 3478, HTTPS via Caddy)
CrowdSec + nftables for intrusion prevention
Authentik (runs in homelab, NOT on VPS) handles all authentication

## Sensitive Value Handling

### Classification

| Value | Sensitive | Storage |
|---|---|---|
| Block device name (vda/sda) | No | Public repo (disko.nix) |
| Boot mode (UEFI/BIOS) | No | Public repo (hardware.nix) |
| CPU cores, RAM, architecture | No | Public repo (hardware.nix) |
| Virtualization type (kvm) | No | Public repo |
| Network interface name (ens3/eth0) | No | Public repo |
| **Public IPv4 address** | **Yes** | Private nix file or sops |
| **Public IPv6 address/prefix** | **Yes** | Private nix file or sops |
| **Default gateway (v4/v6)** | **Yes** | Private nix file or sops |
| **DNS resolver IPs** | **Yes** | Private nix file or sops |
| **WireGuard private key** | **Yes** | sops-nix (runtime secret) |
| **WireGuard tunnel IPs** | **Yes** | Private nix file |
| **WireGuard listen port** | **Yes** | Private nix file |
| WireGuard public key | No | Public repo |
| **CrowdSec API key** | **Yes** | sops-nix (runtime secret) |
| SSH host keys | **Yes** | sops-nix + impermanence persist |

### Two-tier secret strategy

**Tier 1: sops-nix (age-encrypted) – for true runtime secrets**

These are cryptographic keys and tokens that must be decrypted at service activation time. They are opaque file paths at Nix evaluation time. sops-nix handles decryption.

- WireGuard private key
- CrowdSec API key
- SSH host keys
- Any future API tokens

**Tier 2: Private Nix file (.gitignore'd or private flake input) – for sensitive-but-evaluation-time values**

These values are needed during Nix evaluation (not just at runtime) and cannot be sops secrets because NixOS options like `networking.interfaces.*.ipv4.addresses` require concrete values at build time.

Create a file `hosts/cupix001/private.nix` that is either:
- Option A: Listed in `.gitignore` and manually placed (simplest, fine for a single VPS)
- Option B: Sourced from a private flake input (better for multi-host, auditable)

The file must define values consumed by the public configuration via a custom option namespace or a let-binding.

**Pattern:**

```nix
# hosts/cupix001/private.nix (NOT in public repo)
{
  # All values here are needed at Nix evaluation time
  # but must not appear in the public git history.
  networking.cupix001 = {
    publicIPv4 = "203.0.113.42";       # placeholder – replace with real IP
    publicIPv6 = "2a03:4000:xx::1";    # placeholder
    prefixLengthV4 = 22;               # from: ip -4 addr show scope global
    prefixLengthV6 = 64;               # from: ip -6 addr show scope global
    gateway4 = "203.0.113.1";          # from: ip route show default
    gateway6 = "fe80::1";              # from: ip -6 route show default
    dns = ["46.38.225.18" "46.38.252.18"]; # from: cat /etc/resolv.conf (netcup defaults)
    wgListenPort = 51820;
    wgTunnelIPv4 = "10.100.0.1/30";    # VPS side
    wgPeerTunnelIPv4 = "10.100.0.2/30"; # Homelab/IPFire side
  };
}
```

```nix
# hosts/cupix001/networking.nix (public repo)
{ config, ... }:
let
  priv = config.networking.cupix001; # consumed from private.nix
in {
  networking = {
    interfaces.ens3.ipv4.addresses = [{
      address = priv.publicIPv4;
      prefixLength = priv.prefixLengthV4;
    }];
    defaultGateway = { address = priv.gateway4; interface = "ens3"; };
    nameservers = priv.dns;
  };

  networking.wireguard.interfaces.wg0 = {
    listenPort = priv.wgListenPort;
    # privateKeyFile references sops-nix path (Tier 1)
    privateKeyFile = config.sops.secrets."wireguard/private-key".path;
    peers = [{
      publicKey = "HOMELAB_WG_PUBKEY_HERE"; # not sensitive, public repo is fine
      allowedIPs = ["10.100.0.0/30"];
      # No endpoint needed – homelab initiates
      persistentKeepalive = 25; # set on homelab side, not here; included for clarity
    }];
  };
}
```

### Important implementation notes:

- hosts/cupix001/default.nix must import ./private.nix
- The custom option set networking.cupix001 must be declared (via lib.mkOption) either in private.nix itself or in a shared module (e.g., hosts/cupix001/options.nix)
- The VM variant (vmVariant) must override or mock the private values so that the VM can be started without the private file, OR the private file must exist on the build machine (laptop) – which it will, since builds happen locally
- Document in the repo README that hosts/cupix001/private.nix must be created manually from a template before building
- Provide a hosts/cupix001/private.nix.example in the public repo with placeholder values and comments explaining each field

## Gathering values for private.nix

Before first deployment, the user must run the following on the current Debian VPS and populate private.nix:

```bash
# Block device (for disko.nix, public repo)
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT

# Boot mode (for hardware.nix, public repo)
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS/Legacy"

# CPU/RAM (for hardware.nix, public repo)
nproc && free -h && uname -m

# Network – ALL OUTPUT GOES INTO private.nix
ip -br addr
ip -4 addr show scope global
ip -6 addr show scope global
ip route show default
ip -6 route show default
cat /etc/resolv.conf
curl -6 -s https://ifconfig.co || echo "IPv6 not routable"

# Interface name (public repo)
ip -br link | grep -v lo

# Kernel / virt type (informational)
uname -r
systemd-detect-virt

# Boot files (informational – determines grub vs systemd-boot)
ls /boot/

# DHCP or static (determines networkd config)
cat /etc/network/interfaces 2>/dev/null || networkctl status

# Current listeners (conflict check, not persisted)
ss -tlnp
ss -ulnp
```

# # Block device (for disko.nix, public repo)
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT

# Boot mode (for hardware.nix, public repo)
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS/Legacy"

# CPU/RAM (for hardware.nix, public repo)
nproc && free -h && uname -m

# Network – ALL OUTPUT GOES INTO private.nix
ip -br addr
ip -4 addr show scope global
ip -6 addr show scope global
ip route show default
ip -6 route show default
cat /etc/resolv.conf
curl -6 -s https://ifconfig.co || echo "IPv6 not routable"

# Interface name (public repo)
ip -br link | grep -v lo

# Kernel / virt type (informational)
uname -r
systemd-detect-virt

# Boot files (informational – determines grub vs systemd-boot)
ls /boot/

# DHCP or static (determines networkd config)
cat /etc/network/interfaces 2>/dev/null || networkctl status

# Current listeners (conflict check, not persisted)
ss -tlnp
ss -ulnp
```

## Phase 1 Scope (implement this)

### 1. Disk Layout (disko)

- GPT partition table on /dev/vda (or /dev/sda – detect at install time from gathered info)
- vda1: 512M EFI (fat32), mounted at /boot – ONLY if UEFI. If BIOS: use MBR + grub
- vda2: remaining space, btrfs, with subvolumes:
  - @root → / (wiped on every boot via impermanence blank snapshot rollback)
  - @persist → /persist (impermanence persistent state)
  - @nix → /nix (Nix store)
  - @log → /var/log (persistent logs)
- No LVM, no LUKS
- Add `@swap` subvolume with 2G swapfile (OOM prevention on small VPS)
- `fileSystems."/persist".neededForBoot = true` – critical: sops-nix needs /persist before secrets are decrypted
- `fileSystems."/var/log".neededForBoot = true`
- Root-wipe mechanism: create blank snapshot of @root after first boot, rollback in initrd:

  ```nix
  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir -p /mnt
    mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
    btrfs subvolume delete /mnt/@root
    btrfs subvolume snapshot /mnt/@root-blank /mnt/@root
    umount /mnt
  ''
```

Post-deployment step (once, after nixos-anywhere):

```bash
mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
umount /mnt
``` 

- Configure impermanence module: persistent paths for /persist (Caddy certs, CrowdSec DB, WireGuard keys, sops secrets, machine-id, etc.) including:
- /persist/etc/ssh (host keys)
- /persist/var/lib/caddy (certificates, ACME state)
- /persist/var/lib/crowdsec (Phase 2, but reserve path)
- /persist/var/lib/nixos  # UID/GID map – CRITICAL, prevents permission drift after reboot
- /persist/etc/machine-id
- /persist/var/lib/systemd (persistent timers, random-seed)
- sops key file location

### 2. Firewall (nftables)

- Default deny on all interfaces
- Public interface: allow inbound 80/tcp, 443/tcp, 3478/udp (STUN), WireGuard port/udp (from private.nix)
- **Bootstrap SSH: allow inbound on a configurable high port (default 55809/tcp) on public interface, controlled by a boolean flag `networking.cupix001.enablePublicSSH` (default: true). Once WireGuard is verified, set to false and redeploy.**
- WireGuard interface (wg0): allow all (trusted)
- No standard-port (22) SSH on public interface at any time
- Once WireGuard is estabished: no public SSH. SSH only via WireGuard interface
- Allow established/related connections
- Drop invalid packets
- ICMP: allow echo-request rate-limited
- IPv6: mirror IPv4 rules if IPv6 is available (check gathered info)

### 3. WireGuard Tunnel

- Point-to-point tunnel between cupix001 and homelab IPFire
- cupix001 is the passive endpoint (listens on configured port from private.nix)
- Homelab side initiates (PersistentKeepalive = 25)
- Tunnel IPs from private.nix
- Private key via sops-nix (Tier 1 secret)
- Public key in public repo
- Use NixOS native wireguard module (networking.wireguard.interfaces)

## 4. Caddy Reverse Proxy

- Caddy version >= 2.9.2 (critical: forward_auth header security fix CVE GHSA-7r4p-vjf4-gxv4)
- ACME via DNS-01 challenge using netcup CCP DNS API (instead of HTTP-01)
- Requires caddy-dns/netcup plugin (custom Caddy build or nixpkgs overlay)
- Benefit: Port 80 can remain closed in nftables → reduced attack surface
- Benefit: Supports wildcard certificates (*.example.de)
- CCP DNS API credentials (API key, API password, customer number) → sops-nix Tier 1 secrets
- Fallback: HTTP-01 if DNS-01 proves unreliable (netcup DNS API rate limit: 180 req/min)
- Global options: email for ACME, log format
- For each of ~4 services: virtual host block with:
  - `forward_auth` to Authentik in homelab (via WireGuard tunnel IP from private.nix, port 9443)
    - uri: /outpost.goauthentik.io/auth/caddy
    - copy_headers: Remote-User, Remote-Groups, Remote-Email, Remote-Name
    - Strip client-supplied auth headers before forwarding: `header_up -Remote-User`, `header_up -Remote-Groups`, `header_up -Remote-Email`, `header_up -Remote-Name`
  - `reverse_proxy` to homelab backend via WireGuard tunnel IP
- auth.example.de (replace with actual domain): reverse_proxy to Authentik in homelab
- DERP: route derp subdomain to localhost derper process
- Security headers on all responses:
  - Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - Referrer-Policy: strict-origin-when-cross-origin
  - Permissions-Policy: camera=(), microphone=(), geolocation=()
- Use NixOS `services.caddy` module with Caddyfile or JSON config
- Caddy data/config dirs must be in /persist for impermanence
- systemd unit: Restart=on-failure, RestartSec=5s
- Domain names: use placeholder example.de – the user will substitute actual domains

### 5. Standalone DERP Relay

- Use `tailscale/cmd/derper` package from nixpkgs (or build from tailscale source)
- Run as systemd service
- Configure: --hostname=derp.example.de (placeholder), --certmode=manual (Caddy handles TLS), --stun, --a=:3478 for STUN
- HTTPS traffic proxied through Caddy (derper listens on localhost HTTP port, e.g., 8443 or similar)
- STUN listens on 0.0.0.0:3478/udp (directly exposed, not through Caddy)
- systemd unit: Restart=on-failure, RestartSec=5s
- DynamicUser=true or dedicated system user with minimal permissions

### 6. SSH Hardening

- sshd listens on WireGuard interface IP (from private.nix tunnel IP) on port 22
- **Additionally, when `networking.cupix001.enablePublicSSH` is true: sshd also listens on public IP on the high port (from private.nix, default 55809). This is the bootstrap/fallback listener.**
- Once WireGuard connection is established, sshd listens ONLY on WireGuard interface IP
- Key-only authentication (PasswordAuthentication no, KbdInteractiveAuthentication no)
- AllowUsers or AllowGroups restricted
- MaxAuthTries 3
- PermitRootLogin prohibit-password (or no, use sudo)
- No X11Forwarding, no AgentForwarding unless needed
- SSH host keys persisted via impermanence (/persist/etc/ssh)

### 7. Automatic Security Updates

- `system.autoUpgrade.enable = true`
- `system.autoUpgrade.allowReboot = true`
- Configure reboot window (e.g., 03:00-05:00)
- Flake-based: point autoUpgrade to the flake

### 8. Systemd Service Hardening (basic, for all custom units)

- Restart=on-failure, RestartSec=5s for Caddy, derper, WireGuard
- WatchdogSec where supported

### 9. Minimal System Profile

- No build tools (no gcc, no make, no cmake)
- No git on the cupix001
- No curl, wget unless required by a service
- Minimal environment.systemPackages: only diagnostic tools needed (htop, tcpdump, dig optional)
- nix.settings.trusted-users only root
- Disable nix-daemon build capabilities if possible (cupix001 receives pre-built closures only)
- `environment.defaultPackages = []` – removes NixOS default packages (perl, rsync, strace, etc.)

### 10. sops-nix Secrets (Tier 1)

The following secrets must be managed via sops-nix (age-encrypted):

- WireGuard private key
- CrowdSec API key (if applicable in Phase 1, otherwise defer)
- Any Caddy API tokens if needed
- SSH host keys (persist across impermanence wipes)
- CrowdSec API key (Phase 2, but define sops path now)
- Explicit age identity path on /persist:
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  # OR dedicated key file:
  # sops.age.keyFile = "/persist/sops-age-key";
- netcup/ccp-api-key          # CCP DNS API key (used by Caddy for DNS-01 ACME)
- netcup/ccp-api-password      # CCP DNS API password
- netcup/ccp-customer-number   # CCP customer number

Ensure sops secret files are persisted in /persist and referenced correctly by impermanence.
The age key for the cupix001 must be provisioned during nixos-anywhere install (either via --extra-files or by deriving from SSH host key).

### 11. Private Nix File Template

Create hosts/cupix001/private.nix.example in the public repo with:

- All fields from the pattern above with placeholder values
- Comments explaining how to gather each value
- Instructions to copy to private.nix and fill in real values

Add hosts/cupix001/private.nix to .gitignore.

Declare the networking.cupix001 option set in a module (e.g., hosts/cupix001/options.nix) with types and descriptions so that missing values cause clear evaluation errors.

### 12. VM Testing Setup

- Add `virtualisation.vmVariant` to the cupix001 configuration:
  - virtualisation.memorySize = 2048
  - virtualisation.forwardPorts: host 8443 → guest 443, host 8080 → guest 80
  - Mock WireGuard: either disable or use dummy interface
  - Override private.nix values for VM: use localhost/loopback IPs, dummy gateway
  - Caddy: use internal/self-signed TLS for VM testing
  - Disable autoUpgrade in VM variant
  - Skip sops secrets that require real keys (provide mock paths or disable dependent services gracefully)
- The VM must be launchable via: `nix run .#nixosConfigurations.cupix001.config.system.build.vm`
- No code duplication: vmVariant only overrides infrastructure-specific parameters
- The private.nix file with real or mock values must exist on the build machine for evaluation to succeed

### 13. Deployment

**Pre-deployment (before nixos-anywhere touches the VPS):**

1. Authenticate to netcup SCP REST API (Keycloak OIDC)
2. Create firewall policy `cupix001-bootstrap` via API with rules:
   - 443/tcp inbound ALLOW (Caddy)
   - 80/tcp inbound ALLOW (ACME HTTP-01 fallback, first try to use DNS-01)
   - 3478/udp inbound ALLOW (STUN)
   - WireGuard-port/udp inbound ALLOW
   - Bootstrap-SSH-port/tcp inbound ALLOW (e.g., 55809)
   - 22/tcp inbound ALLOW **temporarily** (nixos-anywhere needs Debian's SSH)
   - Default: DENY all other inbound
3. Assign policy `cupix001-bootstrap` to the VPS via API
4. Verify policy is active: attempt connection to a closed port → must be rejected
5. Create pre-install snapshot via SCP REST API
6. Proceed with `nixos-anywhere --flake .#cupix001 root@<DEBIAN-IP>`

**Post-first-boot:**

1. Verify bootstrap SSH on high port: `ssh -p 55809 user@<PUBLIC-IP>`
2. Verify WireGuard tunnel: `ping 10.100.0.2`
3. Verify SSH via WireGuard: `ssh user@10.100.0.1`
4. Verify Caddy: `curl -I https://example.de`
5. Update firewall policy via API → remove 22/tcp rule (Debian SSH no longer needed)
6. Set `networking.cupix001.enablePublicSSH = false`, redeploy via `colmena apply --on @edge`
7. Update firewall policy via API → remove bootstrap-SSH-port rule → final policy `cupix001-production`
8. If DNS-01 active: remove 80/tcp from policy
9. Run testinfra suite

**Ongoing:** `colmena apply --on @edge` via WireGuard

**Rollback:** If nixos-anywhere fails, restore pre-install snapshot via SCP REST API

### 14. Colmena Integration

- Add colmena configuration to the flake that consumes existing nixosConfigurations
- Support deployment tags: @edge for cupix001, @homelab for future homelab hosts
- Ensure colmena works with sops-nix secrets
- colmena targetHost for cupix001 uses WireGuard tunnel IP (from private.nix)
- Build happens on deploying machine, not on target

### 15. Automated Testing

**Layer 1: Nix Evaluation (no VM)**
- Module assertions for logical invariants (e.g., "Caddy enabled implies ports open")
- `lib.mkOption` with strict types on `networking.cupix001` options – missing/wrong values fail at eval time
- `nix flake check` runs all of the above

**Layer 2: NixOS VM Tests (`nixosTest`)**
- Create `checks.x86_64-linux.cupix001-edge-gateway` using `pkgs.nixosTest`
- Import cupix001 configuration, override private values, mock sops secrets
- Test assertions:
  - nftables rules: 80, 443, 3478/udp open; port 22 NOT open on public interface; bootstrap SSH port open when flag true, closed when false
  - caddy.service and derper.service running
  - Ports 443, 80, 3478 listening
  - sshd config: password auth disabled, maxauthtries 3
  - No gcc, git, make in PATH
  - /persist directory exists with expected subdirectories
  - Security headers present in Caddy response
  - Zero failed systemd units
  - btrfs subvolumes correct (`btrfs subvolume list /`)
  - Impermanence: file created in / disappears after reboot, file in /persist survives
- Multi-node test variant (Phase 2): add mock Authentik backend node, test forward_auth flow (401 without auth, 200 with valid header)
- Register in flake `checks` output
- Interactive debugging: `nix build .#checks.x86_64-linux.cupix001-edge-gateway.driverInteractive && ./result/bin/nixos-test-driver`
- Impermanence reboot test:
  ```python
  gateway.succeed("echo 'ephemeral' > /root/test.txt")
  gateway.succeed("echo 'persistent' > /persist/test.txt")
  gateway.shutdown()
  gateway.start()
  gateway.wait_for_unit("multi-user.target")
  gateway.fail("test -f /root/test.txt")        # wiped
  gateway.succeed("test -f /persist/test.txt")   # survived
  ```

- SSH host key stability test:
  ```python
  fp_before = gateway.succeed("ssh-keygen -lf /persist/etc/ssh/ssh_host_ed25519_key.pub").strip()
  gateway.shutdown()
  gateway.start()
  gateway.wait_for_unit("multi-user.target")
  fp_after = gateway.succeed("ssh-keygen -lf /persist/etc/ssh/ssh_host_ed25519_key.pub").strip()
  assert fp_before == fp_after, "SSH host key changed after reboot"
  ```

- ACME persistence test (post-ACME-issuance):
  ```python
  gateway.succeed("test -d /persist/var/lib/caddy")
  gateway.shutdown()
  gateway.start()
  gateway.wait_for_unit("caddy.service")
  gateway.succeed("test -d /persist/var/lib/caddy")
  ```

- Caddy state persistence across reboot:
  ```python
  gateway.succeed("test -d /persist/var/lib/caddy")
  gateway.shutdown()
  gateway.start()
  gateway.wait_for_unit("caddy.service")
  gateway.succeed("test -d /persist/var/lib/caddy")
  ```

- Bootstrap SSH flag test:
  ```python
  # With enablePublicSSH = true:
  gateway.succeed("ss -tlnp | grep ':55809'")
  # After flag flip to false + rebuild (separate test node or reconfigure):
  gateway.fail("ss -tlnp | grep ':55809'")
  ```

**Layer 3: Post-deployment (Testinfra/pytest)**
- `tests/test_cupix001_deployed.py` using testinfra
- Connection via SSH over WireGuard (or bootstrap port)
- Same assertions as VM test, plus real-world checks:
  - WireGuard interface wg0 exists and has correct tunnel IP
  - Real TLS certificate valid (ACME)
  - Tunnel reachable (ping homelab side)
  - DNS resolution works
- Runs on laptop only: `pytest --hosts=ssh://user@<WG-IP> tests/`
- No test dependencies installed on VPS
- Include testinfra in flake devShell
- SSH host key fingerprint matches pre-deployment record
  ```python
  def test_ssh_host_key_stable(host):
      fp = host.check_output("ssh-keygen -lf /persist/etc/ssh/ssh_host_ed25519_key.pub")
      assert fp.strip() == EXPECTED_FINGERPRINT  # from deployment docs
  ```

- ACME certificate present and valid
  ```python
  def test_acme_cert_exists(host):
      assert host.file("/persist/var/lib/caddy").is_directory
      result = host.check_output(
          "curl -sI https://localhost -o /dev/null -w '%{ssl_verify_result}'"
      )
      assert result.strip() == "0"  # valid cert chain
  ```

- WireGuard tunnel reachable
  ```python
  def test_wg_tunnel_connectivity(host):
      assert host.check_output("ping -c1 -W2 10.100.0.2").find("1 received") != -1
  ```

**Test-first workflow:**
1. Write assertion or nixosTest → must fail (Red)
2. Implement module/service config → test passes (Green)
3. Refactor module structure → tests still pass (Refactor)
4. Deploy → Testinfra validates real system

### 16. Deployment Documentation

Create `docs/cupix001-deployment.md` with:

1. **Pre-deployment checklist (in this order):**
   - Gather VPS values, populate `hosts/cupix001/private.nix`
   - Generate WireGuard keypair, add private key to sops
   - Add VPS SSH host key to `sops.yaml`, re-encrypt
   - **Activate Gen12 external firewall via API BEFORE any OS change:**
     ```bash
     ./scripts/netcup-firewall.py --policy bootstrap --server cupix001
     # Verify: nmap -p 22,443,61222 <PUBLIC-IP> (open)
     # Verify: nmap -p 8080 <PUBLIC-IP> (filtered/closed)
     ```
   - Create pre-install snapshot via API
   - Only then: run `nixos-anywhere`

2. First deployment steps:
   - `nixos-anywhere --flake .#cupix001 root@<DEBIAN-IP>`
   - Provision sops age key via `--extra-files`
   - After first boot: create blank btrfs snapshot:

     ```bash
     ssh -p 55809 user@<PUBLIC-IP>
     sudo mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
     sudo btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
     sudo umount /mnt
     ```

   - Verify bootstrap SSH, WireGuard, Caddy
   - Set `enablePublicSSH = false`, redeploy via colmena

3. Ongoing operations:
   - `colmena apply --on @edge` for updates
   - Run testinfra suite after each deploy
   - Monitor auto-upgrade timer

### 17. Netcup External Firewall (Gen12)

**This is step 0 of any deployment. The external firewall MUST be active before
nixos-anywhere runs, before the VPS is exposed with a fresh OS.**

- Two named policies managed via SCP REST API:
  - `cupix001-bootstrap`: includes 22/tcp + bootstrap-SSH-port + production ports
  - `cupix001-production`: only production ports (443/tcp, 3478/udp, WireGuard/udp; 80/tcp only if HTTP-01)
- Policies are account-level objects, assigned to servers on product-level
- Create a deployment script (`scripts/netcup-firewall.py` or `.sh`) that:
  1. Authenticates to SCP REST API via OIDC (Keycloak)
  2. Creates/updates firewall policy from a JSON definition in the repo
  3. Assigns policy to cupix001 server ID (from private.nix)
  4. Verifies assignment
- JSON policy definitions stored in repo (`infra/firewall/cupix001-bootstrap.json`, `cupix001-production.json`) – rules themselves are not sensitive
- SCP API credentials → laptop-only credential store (sops-encrypted file or env vars), never on VPS
- Known limitations:
  - No protocol "ANY" for non-reseller accounts
  - Implicit rules cannot be disabled
  - UDP handling has quirks – test STUN (3478/udp) explicitly after policy assignment
  - No vLAN filtering (external traffic only)
  - NTP (chrony) may require source-port-based rules if strict policy is applied
- Emergency kill-switch: script mode `--lockdown` sets DENY-all policy via API
- SCP REST API credentials (OIDC client-id + client-secret) are laptop-only secrets
- Store in a separate sops-encrypted file on the laptop (e.g., `secrets/laptop/netcup-scp.yaml`)
- These credentials MUST NOT be deployed to the VPS – they grant full server lifecycle control (power, snapshots, firewall)
- Do not add them to the VPS host's sops secrets file

### 18. Automated Pre-Deployment Snapshot

- Before each `nixos-anywhere` or risky `colmena apply`:
  1. Script calls SCP REST API to create server snapshot
  2. Waits for snapshot completion
  3. Proceeds with deployment
  4. On failure: option to restore snapshot via API
- Script runs from laptop
- Integrate into deployment wrapper script or Makefile target:
  ```bash
  make deploy-edge  # snapshot → colmena apply → testinfra
  ```


## Phase 2 Scope (DO NOT implement yet, document as TODO in hardening.nix)

- Kernel sysctl hardening (net.ipv4.conf.all.rp_filter, kernel.kptr_restrict, etc.)
- Full systemd sandboxing per unit (ProtectSystem=strict, PrivateTmp=true, NoNewPrivileges=true, ProtectHome=true, ReadOnlyPaths=/ for all units)
- CrowdSec LAPI + crowdsec-firewall-bouncer (nftables mode)
- Caddy rate limiting
- Geo-blocking via CrowdSec scenarios
- Strip and remove all unnecessary packages from system closure

## Phase 3 Scope (DO NOT implement yet, document as TODO)

- Prometheus node-exporter (listen only on WireGuard interface)
- Alerting pipeline
- AppArmor profiles for Caddy and derper (NixOS AppArmor support is immature – profiles must be manually written)
- Log forwarding to homelab (journald-remote or Loki)

## Constraints

- All builds happen on the deploying machine (laptop), NOT on the cupix001
- cupix001 has no git, no compilers, no build tools
- Use pre-built packages from nixpkgs cache wherever possible
- NixOS unstable or 24.11+ channel (ensure Caddy >= 2.9.2 is available)
- The cupix001 configuration integrates into the existing flake mono-repo under hosts/cupix001/
- Secrets in sops-nix (age), keys in the existing sops setup, two tier strategy as described above
- Sensitive network values: never in public repo, always    .nix or sops

## Testing Workflow

1. `nix flake check` – evaluate, catch type errors
2. `nix build .#nixosConfigurations.cupix001.config.system.build.toplevel` – full closure builds
3. `nix run .#nixosConfigurations.cupix001.config.system.build.vm` – start VM, verify:
   - Caddy starts and responds on forwarded ports
   - nftables rules are loaded (check with `nft list ruleset` in VM)
   - derper process is running
   - systemd units are healthy (systemctl --failed)
   - impermanence: / is wiped subvolume, /persist exists
   - SSH not listening on non-WireGuard interfaces
4. nixos-anywhere to real cupix001 (first time only)
5. `colmena apply --on @edge` for subsequent updates

## Important Security Notes

- Caddy MUST be >= 2.9.2 due to forward_auth header injection vulnerability (GHSA-7r4p-vjf4-gxv4)
- Always strip client-supplied Remote-User/Remote-Groups/Remote-Email headers before forward_auth
- First deploy via nixos-anywhere needs temporary public SSH on Debian; immediately locked down after WireGuard is established on NixOS
- Authentik unavailability = 502 for all protected services (intentional, zero-trust, no fallback to unauthenticated access)
- No sensitive values (IPs, gateways, tunnel config) in public git history

## File Structure (expected)

```
hosts/
  cupix001/
    default.nix              # Main host config, imports all sub-modules
    hardware.nix             # KVM-specific: boot, kernel, CPU, non-sensitive HW
    disko.nix                # Disk layout (btrfs, subvolumes, no LUKS)
    options.nix              # Declares networking.cupix001 option set with types
    private.nix              # GITIGNORED – real sensitive network values
    private.nix.example      # Template with placeholders and instructions
    networking.nix           # nftables, WireGuard – consumes networking.cupix001
    caddy.nix                # Reverse proxy, forward_auth, security headers
    derper.nix               # DERP relay service
    hardening.nix            # SSH hardening, minimal packages, Phase 2 TODOs
    impermanence.nix         # Persistent paths declaration
modules/
  edge/                      # Reusable edge-proxy modules (if applicable)
scripts/
  netcup-firewall.py           # Manages Gen12 firewall policies via SCP REST API
infra/
  firewall/
    cupix001-bootstrap.json    # Firewall policy: bootstrap phase (incl. temp SSH)
    cupix001-production.json   # Firewall policy: production (minimal ports)
```

Adapt to match existing repo conventions. The key constraint is: private.nix must never be committed to the public repo.
