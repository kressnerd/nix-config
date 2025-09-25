# Declarative SSH Key Management for initrd

This document explores declarative approaches to SSH key management that align with Nix's core principles of reproducibility, immutability, and system-wide consistency.

## The Problem with Manual Key Generation

The current approach of manually generating SSH keys violates several Nix principles:

```bash
# ❌ Imperative approach - violates Nix philosophy
sudo ./scripts/generate-initrd-keys.sh
sudo nixos-rebuild switch
```

**Issues:**

- **Non-reproducible**: Different keys on each deployment
- **Stateful**: Relies on filesystem state outside of Nix store
- **Manual steps**: Requires human intervention for each deployment
- **Inconsistent**: No guarantee keys exist before deployment

## Declarative Solutions

### Option 1: Activation Scripts (Recommended)

Use NixOS activation scripts to automatically generate keys during system activation:

```nix
# In hardware.nix or a dedicated module
system.activationScripts.initrd-ssh-hostkeys = {
  text = ''
    # Create directory for initrd SSH keys
    mkdir -p /etc/secrets/initrd
    chmod 700 /etc/secrets/initrd

    # Generate RSA key if it doesn't exist
    if [[ ! -f /etc/secrets/initrd/ssh_host_rsa_key ]]; then
      ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -N "" \
        -f /etc/secrets/initrd/ssh_host_rsa_key \
        -C "initrd-rsa-$(hostname)"
      chmod 600 /etc/secrets/initrd/ssh_host_rsa_key
      chmod 644 /etc/secrets/initrd/ssh_host_rsa_key.pub
    fi

    # Generate Ed25519 key if it doesn't exist
    if [[ ! -f /etc/secrets/initrd/ssh_host_ed25519_key ]]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
        -f /etc/secrets/initrd/ssh_host_ed25519_key \
        -C "initrd-ed25519-$(hostname)"
      chmod 600 /etc/secrets/initrd/ssh_host_ed25519_key
      chmod 644 /etc/secrets/initrd/ssh_host_ed25519_key.pub
    fi
  '';
  deps = []; # Run early in activation
};

boot.initrd.network.ssh = {
  enable = true;
  port = 2222;
  shell = "/bin/cryptsetup-askpass";
  hostKeys = [
    "/etc/secrets/initrd/ssh_host_rsa_key"
    "/etc/secrets/initrd/ssh_host_ed25519_key"
  ];
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ dan"
  ];
};
```

**Benefits:**

- ✅ **Fully declarative**: No manual steps required
- ✅ **Idempotent**: Keys generated only if missing
- ✅ **Automatic**: Works on first deployment
- ✅ **Consistent**: Same configuration everywhere

### Option 2: Pre-generated Keys in Nix Store

For completely deterministic deployments, pre-generate keys and include them in the Nix store:

```nix
# Generate keys once and commit to repository
# NOTE: These keys are NOT SECRET - stored in Nix store
let
  initrdKeys = {
    rsa = {
      private = ./secrets/initrd_rsa_key;
      public = ./secrets/initrd_rsa_key.pub;
    };
    ed25519 = {
      private = ./secrets/initrd_ed25519_key;
      public = ./secrets/initrd_ed25519_key.pub;
    };
  };
in {
  # Copy pre-generated keys during activation
  system.activationScripts.initrd-ssh-hostkeys = {
    text = ''
      mkdir -p /etc/secrets/initrd
      chmod 700 /etc/secrets/initrd

      # Copy pre-generated keys from Nix store
      cp ${initrdKeys.rsa.private} /etc/secrets/initrd/ssh_host_rsa_key
      cp ${initrdKeys.rsa.public} /etc/secrets/initrd/ssh_host_rsa_key.pub
      cp ${initrdKeys.ed25519.private} /etc/secrets/initrd/ssh_host_ed25519_key
      cp ${initrdKeys.ed25519.public} /etc/secrets/initrd/ssh_host_ed25519_key.pub

      # Set correct permissions
      chmod 600 /etc/secrets/initrd/ssh_host_*_key
      chmod 644 /etc/secrets/initrd/ssh_host_*_key.pub
    '';
  };

  boot.initrd.network.ssh = {
    # ... same as above
  };
}
```

**Benefits:**

- ✅ **Fully reproducible**: Identical keys across all deployments
- ✅ **Version controlled**: Keys tracked in git
- ✅ **Immediate deployment**: Works from first boot

**Trade-offs:**

- ⚠️ **Fixed keys**: Same keys across all instances
- ⚠️ **Repository size**: Binary keys in git

### Option 3: SOPS/Age Secret Management

Use SOPS (Secrets OPerationS) with age encryption for encrypted key management:

```nix
# secrets.yaml (encrypted with SOPS)
initrd_ssh_rsa_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  [encrypted content]
  -----END OPENSSH PRIVATE KEY-----

initrd_ssh_ed25519_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  [encrypted content]
  -----END OPENSSH PRIVATE KEY-----
```

```nix
# In configuration
sops.secrets = {
  "initrd_ssh_rsa_key" = {
    sopsFile = ./secrets.yaml;
    path = "/etc/secrets/initrd/ssh_host_rsa_key";
    mode = "0600";
  };
  "initrd_ssh_ed25519_key" = {
    sopsFile = ./secrets.yaml;
    path = "/etc/secrets/initrd/ssh_host_ed25519_key";
    mode = "0600";
  };
};

boot.initrd.network.ssh = {
  enable = true;
  port = 2222;
  shell = "/bin/cryptsetup-askpass";
  hostKeys = [
    config.sops.secrets."initrd_ssh_rsa_key".path
    config.sops.secrets."initrd_ssh_ed25519_key".path
  ];
  # ... rest of config
};
```

**Benefits:**

- ✅ **Encrypted storage**: Keys encrypted in repository
- ✅ **Access control**: Only authorized systems can decrypt
- ✅ **Reproducible**: Same encrypted keys everywhere

### Option 4: Deterministic Key Generation

Generate keys deterministically from a seed for reproducible but unique keys:

```nix
let
  # System-specific seed (could be derived from hostname, machine-id, etc.)
  hostSeed = builtins.hashString "sha256" "${config.networking.hostName}-initrd-ssh";
in {
  system.activationScripts.initrd-ssh-hostkeys = {
    text = ''
      mkdir -p /etc/secrets/initrd
      chmod 700 /etc/secrets/initrd

      # Generate deterministic keys using host-specific seed
      # Note: This is a conceptual example - real implementation would need
      # a cryptographically secure deterministic key generation method

      if [[ ! -f /etc/secrets/initrd/ssh_host_ed25519_key ]]; then
        # Use seed to generate deterministic key
        echo "${hostSeed}" | ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
          -f /etc/secrets/initrd/ssh_host_ed25519_key >/dev/null 2>&1
        chmod 600 /etc/secrets/initrd/ssh_host_ed25519_key
        chmod 644 /etc/secrets/initrd/ssh_host_ed25519_key.pub
      fi
    '';
  };
}
```

## Comparison Matrix

| Approach           | Reproducible | Secure Storage | Auto-Deploy | Unique Keys | Complexity |
| ------------------ | ------------ | -------------- | ----------- | ----------- | ---------- |
| Manual Generation  | ❌           | ⚠️             | ❌          | ✅          | Low        |
| Activation Scripts | ⚠️           | ❌             | ✅          | ✅          | Low        |
| Pre-generated      | ✅           | ❌             | ✅          | ❌          | Low        |
| SOPS/Age           | ✅           | ✅             | ✅          | ✅          | Medium     |
| Deterministic      | ✅           | ❌             | ✅          | ✅          | High       |

## Recommended Implementation

For most use cases, **Option 1 (Activation Scripts)** provides the best balance of simplicity and declarative principles:

```nix
{ config, pkgs, ... }: {
  # Declarative SSH key generation for initrd
  system.activationScripts.initrd-ssh-hostkeys = {
    text = ''
      mkdir -p /etc/secrets/initrd
      chmod 700 /etc/secrets/initrd

      for key_type in rsa ed25519; do
        key_file="/etc/secrets/initrd/ssh_host_''${key_type}_key"
        if [[ ! -f "$key_file" ]]; then
          case "$key_type" in
            rsa)
              ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -N "" -f "$key_file"
              ;;
            ed25519)
              ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f "$key_file"
              ;;
          esac
          chmod 600 "$key_file"
          chmod 644 "$key_file.pub"
        fi
      done
    '';
    deps = [];
  };

  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    shell = "/bin/cryptsetup-askpass";
    hostKeys = [
      "/etc/secrets/initrd/ssh_host_rsa_key"
      "/etc/secrets/initrd/ssh_host_ed25519_key"
    ];
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ dan"
    ];
  };
}
```

## Benefits of the Declarative Approach

### 1. **True Single-Step Deployment**

```bash
# ✅ One command deployment
./scripts/deploy-vm.sh deploy nixos-vm-minimal <VM_IP>
# SSH keys automatically generated during activation
# Remote LUKS unlocking works immediately after reboot
```

### 2. **Reproducible Infrastructure**

- Same configuration produces same system behavior
- No manual steps to forget or execute incorrectly
- Infrastructure as Code principles fully realized

### 3. **Immutable Configuration**

- SSH key generation logic is part of the system configuration
- Changes to key generation are versioned with the rest of the system
- Rollbacks include key generation behavior

### 4. **System-Wide Consistency**

- All systems deployed from same configuration behave identically
- No divergence from manual intervention
- Predictable and testable deployments

## Security Considerations

### SSH Keys in Nix Store

- **By design**: SSH host keys provide authentication, not confidentiality
- **Public anyway**: SSH host keys are revealed during connection
- **Standard practice**: Similar to how NixOS generates regular SSH host keys

### Key Rotation

```nix
# Force key regeneration by adding timestamp or version
system.activationScripts.initrd-ssh-hostkeys = {
  text = ''
    # Add version/timestamp to force regeneration when needed
    key_version="v2-2024-09"

    for key_type in rsa ed25519; do
      key_file="/etc/secrets/initrd/ssh_host_''${key_type}_key"
      version_file="$key_file.version"

      if [[ ! -f "$version_file" ]] || [[ "$(cat "$version_file")" != "$key_version" ]]; then
        # Regenerate key for new version
        ${pkgs.openssh}/bin/ssh-keygen -t "$key_type" -N "" -f "$key_file"
        echo "$key_version" > "$version_file"
        chmod 600 "$key_file"
        chmod 644 "$key_file.pub"
      fi
    done
  '';
};
```

## Integration with Existing Systems

This approach integrates seamlessly with:

- **nixos-anywhere**: Works with automated deployments
- **CI/CD pipelines**: Fully automated, no manual steps
- **Infrastructure as Code**: Declarative configuration only
- **Testing**: Reproducible test environments

The declarative approach transforms SSH key management from an operational burden into a natural part of the system configuration, fully aligned with Nix's philosophy.
