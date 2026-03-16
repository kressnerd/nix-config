# Skill: NixOS Server Administration

**Applies to**: architect, code, debug, nix-expert
**Trigger**: Configuring system services, systemd units, disk management, boot, or impermanence

## Scope

Deep expertise in NixOS system-level configuration: services, systemd hardening, disk management with disko, impermanence patterns, and boot configuration. Extends `.roo/rules/10-nix-senior-admin.md` with production-depth server knowledge.

## Prerequisites (from existing rules)

- Senior Nix admin persona: `.roo/rules/10-nix-senior-admin.md`
- Repository layout: `.roo/rules/11-repository-conventions.md`
- Editing safety: `.roo/rules-code/02-editing-safety.md`
- Troubleshooting: `.roo/rules-code/04-troubleshooting.md`

---

## 1. Service Configuration Patterns

### Standard Service Module

```nix
# hosts/<hostname>/<service>.nix
{ config, lib, pkgs, ... }:
{
  services.<name> = {
    enable = true;
    # Service-specific options
  };

  # Firewall integration
  networking.firewall.allowedTCPPorts = [ <port> ];

  # Optionally: dedicated user/group
  users.users.<service-user> = {
    isSystemUser = true;
    group = "<service-group>";
  };
  users.groups.<service-group> = {};
}
```

### Service State and Data Directories

```nix
# For services that need persistent state on impermanence systems
environment.persistence."/persist/system" = {
  directories = [
    "/var/lib/<service-name>"
    "/var/log/<service-name>"
  ];
};
```

### Service Dependencies

```nix
systemd.services.<name> = {
  after = [ "network-online.target" "sops-nix.service" ];
  wants = [ "network-online.target" ];
  requires = [ "sops-nix.service" ];
};
```

---

## 2. systemd Hardening

### Security Directives

```nix
systemd.services.<name>.serviceConfig = {
  # User isolation
  DynamicUser = true;              # Or use dedicated user
  User = "<user>";
  Group = "<group>";

  # Filesystem restrictions
  ProtectHome = true;              # No access to /home
  ProtectSystem = "strict";        # Read-only /usr, /boot, /etc
  ReadWritePaths = [ "/var/lib/<name>" ];
  PrivateTmp = true;               # Isolated /tmp
  
  # Capability restrictions
  NoNewPrivileges = true;
  CapabilityBoundingSet = "";      # Drop all capabilities
  AmbientCapabilities = "";
  
  # Network isolation (if service doesn't need network)
  PrivateNetwork = false;          # Set true for offline services
  RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
  
  # System call filtering
  SystemCallFilter = [ "@system-service" ];
  SystemCallArchitectures = "native";
  
  # Misc hardening
  LockPersonality = true;
  MemoryDenyWriteExecute = true;
  ProtectClock = true;
  ProtectControlGroups = true;
  ProtectKernelLogs = true;
  ProtectKernelModules = true;
  ProtectKernelTunables = true;
  RestrictNamespaces = true;
  RestrictRealtime = true;
  RestrictSUIDSGID = true;
};
```

### Hardening Analysis

```bash
# Check hardening score of a running service
systemd-analyze security <service-name>
```

---

## 3. Nginx Reverse Proxy

### Standard Reverse Proxy Pattern

```nix
services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  recommendedTlsSettings = true;
  recommendedOptimisation = true;
  recommendedGzipSettings = true;

  virtualHosts."example.com" = {
    forceSSL = true;
    enableACME = true;  # Or useACMEHost for wildcard
    
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;  # If needed
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
      '';
    };
  };
};

# ACME configuration
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
};
```

### ACME with DNS-01 Challenge

```nix
security.acme.certs."example.com" = {
  domain = "*.example.com";
  dnsProvider = "cloudflare";
  credentialFiles = {
    CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-api-token.path;
  };
};
```

---

## 4. Disko — Declarative Disk Management

### Basic GPT + ext4

```nix
# hosts/<hostname>/disko.nix
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
```

### Btrfs with Subvolumes (for impermanence)

```nix
root = {
  size = "100%";
  content = {
    type = "btrfs";
    extraArgs = [ "-f" ];
    subvolumes = {
      "/root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
      "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
      "/nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
      "/persist" = { mountpoint = "/persist"; mountOptions = [ "compress=zstd" "noatime" ]; };
      "/swap" = { mountpoint = "/swap"; swap.swapfile.size = "4G"; };
    };
  };
};
```

---

## 5. Impermanence

### System-Level Persistence

```nix
# hosts/<hostname>/impermanence.nix
{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # Root filesystem is ephemeral (tmpfs or btrfs rollback)
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/sops-nix"
      # Service-specific state
      "/var/lib/<service>"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
```

### Home-Level Persistence (via Home Manager)

```nix
# home/dan/features/linux/impermanence.nix
{ inputs, ... }:
{
  imports = [ inputs.impermanence.homeManagerModules.impermanence ];

  home.persistence."/persist/home/dan" = {
    allowOther = true;
    directories = [
      ".ssh"
      ".gnupg"
      ".local/share/keyrings"
      # Application-specific
      "Documents"
      "Projects"
      ".config/keepassxc"
    ];
    files = [
      ".bash_history"
    ];
  };
}
```

### Impermanence Debugging

```bash
# Check what's NOT persisted
find / -maxdepth 3 -not -path '/nix/*' -not -path '/proc/*' -not -path '/sys/*' -not -path '/persist/*' 2>/dev/null

# Check persisted paths
ls -la /persist/system/
ls -la /persist/home/dan/

# After reboot: check if service state survived
systemctl status <service>
journalctl -b -u <service>
```

---

## 6. Boot Configuration

### GRUB (BIOS/Legacy)

```nix
boot.loader.grub = {
  enable = true;
  device = "/dev/sda";
  efiSupport = false;
};
```

### systemd-boot (UEFI)

```nix
boot.loader.systemd-boot = {
  enable = true;
  configurationLimit = 10;  # Keep last 10 generations
};
boot.loader.efi.canTouchEfiVariables = true;
```

### Kernel Configuration

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;  # Or _lts, _zen
boot.kernelModules = [ "kvm-intel" ];              # Or kvm-amd
boot.extraModulePackages = [ ];
boot.kernelParams = [ "quiet" "splash" ];
boot.initrd.kernelModules = [ ];
boot.initrd.availableKernelModules = [
  "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod"
];
```

### ⚠️ Safety: Boot Changes

Boot configuration changes are **DANGEROUS**. Always:
1. Verify current boot method before changing
2. Keep at least 5 generations: `boot.loader.systemd-boot.configurationLimit = 10;`
3. Test with `nixos-rebuild test` before `switch`
4. Have physical/IPMI access for remote servers
5. Document rollback: `nixos-rebuild switch --rollback`

---

## 7. User and Group Management

```nix
users.users.dan = {
  isNormalUser = true;
  description = "Daniel";
  extraGroups = [ "wheel" "networkmanager" "docker" ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... dan@host"
  ];
  hashedPasswordFile = config.sops.secrets.dan-password.path;
  shell = pkgs.zsh;
};

users.mutableUsers = false;  # Declarative-only user management
```

---

## 8. Monitoring and Logging

### Journal Configuration

```nix
services.journald.extraConfig = ''
  SystemMaxUse=500M
  MaxRetentionSec=1month
'';
```

### Useful Diagnostic Commands

| Command | Purpose |
|---------|---------|
| `systemctl list-units --failed` | List failed services |
| `journalctl -b -p err` | Errors since boot |
| `journalctl -u <service> -f` | Follow service log |
| `systemd-analyze blame` | Boot time per service |
| `systemd-analyze critical-chain` | Boot dependency chain |
| `nixos-rebuild list-generations` | List system generations |
| `nix profile diff-closures --profile /nix/var/nix/profiles/system` | Closure diff between generations |
