# Skill: Network & Security Administration

**Applies to**: architect, code, debug, nix-expert
**Trigger**: Configuring firewall rules, SSH, VPN/WireGuard, TLS certificates, DNS, or security hardening

## Scope

Deep expertise in NixOS networking and security: firewall configuration, SSH hardening, VPN setup (WireGuard/Headscale), TLS/ACME certificate management, DNS, and system security hardening.

## Prerequisites (from existing rules)

- Senior Nix admin persona: `.roo/rules/10-nix-senior-admin.md`
- Repository layout: `.roo/rules/11-repository-conventions.md`
- Editing safety (dangerous changes): `.roo/rules-code/02-editing-safety.md`
- Server administration: `.roo/skills/nixos-server/SKILL.md`

---

## 1. Firewall Configuration

### iptables-based (default)

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 80 443 ];
  allowedUDPPorts = [ 51820 ];  # WireGuard
  
  # Per-interface rules
  interfaces."wg0".allowedTCPPorts = [ 8080 ];
  
  # Rich rules
  extraCommands = ''
    iptables -A INPUT -s 10.0.0.0/24 -j ACCEPT
  '';
};
```

### nftables (modern alternative)

```nix
networking.nftables.enable = true;
networking.firewall = {
  enable = true;
  # Same options work with nftables backend
};
```

### ⚠️ Safety

- ALWAYS keep SSH port (22) open when configuring firewall on remote servers
- Test with `nixos-rebuild test` before `switch` on remote hosts
- Have IPMI/console access as fallback for remote servers
- Use `networking.firewall.logRefusedConnections = true;` for debugging

---

## 2. SSH Hardening

### Server Configuration

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "prohibit-password";  # Or "no"
    X11Forwarding = false;
    MaxAuthTries = 3;
    LoginGraceTime = 20;
    AllowUsers = [ "dan" ];
  };
  
  # Only allow ed25519 host keys
  hostKeys = [
    { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
  ];
  
  # Modern ciphers only
  extraConfig = ''
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
  '';
};
```

### Client Configuration (via Home Manager)

```nix
programs.ssh = {
  enable = true;
  matchBlocks = {
    "server" = {
      hostname = "server.example.com";
      user = "dan";
      identityFile = "~/.ssh/id_ed25519";
      forwardAgent = false;
    };
    "*.internal" = {
      proxyJump = "bastion";
      user = "dan";
    };
  };
  extraConfig = ''
    AddKeysToAgent yes
  '';
};
```

---

## 3. WireGuard VPN

### Server (NixOS)

```nix
networking.wg-quick.interfaces.wg0 = {
  address = [ "10.100.0.1/24" ];
  listenPort = 51820;
  privateKeyFile = config.sops.secrets.wg-private-key.path;
  
  peers = [
    {
      publicKey = "CLIENT_PUBLIC_KEY";
      allowedIPs = [ "10.100.0.2/32" ];
    }
  ];
  
  # IP forwarding and NAT for internet access through VPN
  postUp = ''
    ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
    ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  '';
  preDown = ''
    ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
    ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
  '';
};

# Enable IP forwarding
boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

# Firewall
networking.firewall.allowedUDPPorts = [ 51820 ];
```

### Client

```nix
networking.wg-quick.interfaces.wg0 = {
  address = [ "10.100.0.2/24" ];
  privateKeyFile = config.sops.secrets.wg-private-key.path;
  dns = [ "10.100.0.1" ];

  peers = [
    {
      publicKey = "SERVER_PUBLIC_KEY";
      endpoint = "server.example.com:51820";
      allowedIPs = [ "0.0.0.0/0" ];  # Route all traffic, or specific subnets
      persistentKeepalive = 25;
    }
  ];
};
```

### WireGuard Key Generation

```bash
# Generate key pair
wg genkey | tee privatekey | wg pubkey > publickey

# Store private key in sops
sops hosts/<hostname>/secrets.yaml
# Add: wg-private-key: "<private-key-content>"
```

---

## 4. Headscale (Self-hosted Tailscale)

```nix
# This repo uses Headscale — see hosts/cupix001/headscale.nix

services.headscale = {
  enable = true;
  address = "0.0.0.0";
  port = 8080;
  settings = {
    server_url = "https://headscale.example.com";
    dns.base_domain = "example.internal";
    dns.magic_dns = true;
    dns.nameservers.global = [ "1.1.1.1" "8.8.8.8" ];
  };
};

# Reverse proxy via nginx
services.nginx.virtualHosts."headscale.example.com" = {
  forceSSL = true;
  enableACME = true;
  locations."/" = {
    proxyPass = "http://127.0.0.1:8080";
    proxyWebsockets = true;
  };
};
```

---

## 5. TLS/ACME Certificate Management

### HTTP-01 Challenge (standard)

```nix
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
};

services.nginx.virtualHosts."example.com" = {
  enableACME = true;
  forceSSL = true;
};
```

### DNS-01 Challenge (wildcard certs)

```nix
security.acme.certs."example.com" = {
  domain = "*.example.com";
  extraDomainNames = [ "example.com" ];
  dnsProvider = "cloudflare";
  credentialFiles = {
    CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-token.path;
  };
  group = "nginx";
};

# Use shared certificate
services.nginx.virtualHosts."app.example.com" = {
  useACMEHost = "example.com";
  forceSSL = true;
};
```

### Certificate Debugging

```bash
# Check certificate status
systemctl status acme-example.com.service
journalctl -u acme-example.com.service

# Manual renewal
systemctl start acme-example.com.service

# Check certificate details
openssl s_client -connect example.com:443 -servername example.com | openssl x509 -noout -text
```

---

## 6. DNS Configuration

### systemd-resolved

```nix
services.resolved = {
  enable = true;
  dnssec = "true";
  domains = [ "~." ];  # Use for all domains
  fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
};
```

### Static DNS

```nix
networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
networking.search = [ "example.internal" ];
```

---

## 7. System Security Hardening

### Basic Hardening

```nix
# Kernel hardening
boot.kernel.sysctl = {
  "kernel.unprivileged_bpf_disabled" = 1;
  "net.core.bpf_jit_harden" = 2;
  "kernel.yama.ptrace_scope" = 1;
  "net.ipv4.conf.all.rp_filter" = 1;
  "net.ipv4.conf.default.rp_filter" = 1;
  "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  "net.ipv4.conf.all.accept_redirects" = 0;
  "net.ipv4.conf.default.accept_redirects" = 0;
  "net.ipv6.conf.all.accept_redirects" = 0;
};

# Disable unused network protocols
boot.blacklistedKernelModules = [
  "dccp" "sctp" "rds" "tipc"
];

# Sudo hardening
security.sudo = {
  execWheelOnly = true;
  extraConfig = ''
    Defaults lecture = never
    Defaults passwd_timeout = 1
  '';
};
```

### Fail2ban

```nix
services.fail2ban = {
  enable = true;
  maxretry = 3;
  bantime = "1h";
  bantime-increment.enable = true;
  jails.sshd = {
    settings = {
      filter = "sshd";
      action = "iptables-multiport[name=ssh, port=ssh]";
      maxretry = 3;
    };
  };
};
```

---

## 8. Network Interface Configuration

### NetworkManager (desktop/laptop)

```nix
networking.networkmanager.enable = true;
# Note: mutually exclusive with networking.wireless
```

### systemd-networkd (server)

```nix
systemd.network = {
  enable = true;
  networks."10-lan" = {
    matchConfig.Name = "eth0";
    networkConfig = {
      DHCP = "yes";
      # Or static:
      # Address = "192.168.1.100/24";
      # Gateway = "192.168.1.1";
      # DNS = [ "1.1.1.1" ];
    };
  };
};
```

### ⚠️ Safety: Network Changes

Network misconfigurations on remote servers can cause **permanent loss of access**.

Checklist before applying network changes:
- [ ] SSH port remains open in firewall
- [ ] DNS resolution still works after change
- [ ] Default gateway is reachable
- [ ] Have out-of-band access (IPMI, console, physical)
- [ ] Test with `nixos-rebuild test` first (reverts on failure)
- [ ] Consider `nixos-rebuild switch --rollback` if needed
