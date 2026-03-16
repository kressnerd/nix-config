# Skill: SOPS Secrets Management

**Applies to**: architect, code, debug
**Trigger**: Managing secrets, configuring sops-nix, key rotation, or debugging decryption issues

## Scope

Deep expertise in sops-nix secrets management: `.sops.yaml` configuration, age key management, secret lifecycle, and troubleshooting. This is critical knowledge since this repo uses sops-nix for ALL secret management.

## Prerequisites (from existing rules)

- Secrets hygiene: `.roo/rules/10-nix-senior-admin.md` (Secrets Hygiene principle)
- Editing safety: `.roo/rules-code/02-editing-safety.md` (NEVER commit plaintext secrets)
- Repository layout: `.roo/rules/11-repository-conventions.md` (secrets.yaml locations)

---

## 1. Architecture Overview

```
.sops.yaml                    # Encryption rules (which keys encrypt which files)
hosts/<hostname>/secrets.yaml  # Encrypted secrets per host
```

### How It Works

1. Secrets are encrypted at rest in `secrets.yaml` files using age keys
2. `sops-nix` NixOS module decrypts secrets at activation time
3. Decrypted secrets are placed in `/run/secrets/` (tmpfs, not on disk)
4. Services reference secrets via `config.sops.secrets.<name>.path`

---

## 2. `.sops.yaml` Configuration

```yaml
# .sops.yaml
keys:
  # User keys (for editing secrets)
  - &user_dan age1...  # Dan's personal age key
  
  # Host keys (for decrypting at runtime)
  - &host_thiniel age1...
  - &host_cupix001 age1...
  - &host_J6G6Y9JK7L age1...

creation_rules:
  # Per-host secrets
  - path_regex: hosts/thiniel/secrets\.yaml$
    key_groups:
      - age:
          - *user_dan
          - *host_thiniel

  - path_regex: hosts/cupix001/secrets\.yaml$
    key_groups:
      - age:
          - *user_dan
          - *host_cupix001

  - path_regex: hosts/J6G6Y9JK7L/secrets\.yaml$
    key_groups:
      - age:
          - *user_dan
          - *host_J6G6Y9JK7L
```

### Key Principles

- Each host can ONLY decrypt its own secrets
- The user key (Dan) can decrypt ALL secrets (for editing)
- Adding a new host: add host key + creation rule
- VM variants share their parent host's secrets or have separate rules

---

## 3. Age Key Locations

| Context | Key Path |
|---------|----------|
| NixOS host | `/var/lib/sops-nix/key.txt` |
| NixOS with impermanence | `/persist/var/lib/sops-nix/key.txt` (persisted) |
| macOS (nix-darwin) | `~/Library/Application Support/sops/age/keys.txt` |
| User (for editing) | `~/.config/sops/age/keys.txt` |

### Generate a New Age Key

```bash
# Install age
nix shell nixpkgs#age

# Generate key pair
age-keygen -o key.txt
# Outputs: public key: age1...
# Private key stored in key.txt
```

### Deploy Key to Host

```bash
# For NixOS
ssh root@host "mkdir -p /var/lib/sops-nix && cat > /var/lib/sops-nix/key.txt" < key.txt
ssh root@host "chmod 600 /var/lib/sops-nix/key.txt"

# For impermanence hosts
ssh root@host "mkdir -p /persist/var/lib/sops-nix && cat > /persist/var/lib/sops-nix/key.txt" < key.txt

# For macOS
mkdir -p ~/Library/Application\ Support/sops/age/
cp key.txt ~/Library/Application\ Support/sops/age/keys.txt
```

---

## 4. Secret Operations

### Create/Edit Secrets

```bash
# Edit existing secrets file
sops hosts/<hostname>/secrets.yaml

# Create new secrets file (uses .sops.yaml rules)
sops hosts/<new-hostname>/secrets.yaml
```

### Secret Format in YAML

```yaml
# hosts/<hostname>/secrets.yaml (decrypted view)
user-password: "$6$rounds=..."
wg-private-key: "PRIVATE_KEY_CONTENT"
api-token: "tok-12345..."
```

### Reference in NixOS Configuration

```nix
# hosts/<hostname>/default.nix
{ config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    # Or for impermanence:
    # age.keyFile = "/persist/var/lib/sops-nix/key.txt";
    
    secrets = {
      user-password = {
        neededForUsers = true;  # Available before user activation
      };
      wg-private-key = {
        owner = "root";
        mode = "0400";
      };
      api-token = {
        owner = config.services.myapp.user;
        group = config.services.myapp.group;
        mode = "0440";
        restartUnits = [ "myapp.service" ];  # Restart on secret change
      };
    };
  };

  # Use in service configuration
  users.users.dan.hashedPasswordFile = config.sops.secrets.user-password.path;
  networking.wg-quick.interfaces.wg0.privateKeyFile = config.sops.secrets.wg-private-key.path;
}
```

---

## 5. Adding a New Host's Secrets

### Step-by-Step

1. **Generate age key** for the new host:
   ```bash
   age-keygen -o /tmp/new-host-key.txt
   # Note the public key: age1...
   ```

2. **Add to `.sops.yaml`**:
   ```yaml
   keys:
     - &host_newhost age1...  # Add public key
   
   creation_rules:
     - path_regex: hosts/newhost/secrets\.yaml$
       key_groups:
         - age:
             - *user_dan
             - *host_newhost
   ```

3. **Create secrets file**:
   ```bash
   sops hosts/newhost/secrets.yaml
   ```

4. **Deploy private key** to host:
   ```bash
   ssh root@newhost "mkdir -p /var/lib/sops-nix"
   scp /tmp/new-host-key.txt root@newhost:/var/lib/sops-nix/key.txt
   ssh root@newhost "chmod 600 /var/lib/sops-nix/key.txt"
   ```

5. **Clean up**: Delete `/tmp/new-host-key.txt`

---

## 6. Key Rotation

### Rotate User Key

1. Generate new age key
2. Update `.sops.yaml` with new public key
3. Re-encrypt ALL secrets files:
   ```bash
   sops updatekeys hosts/thiniel/secrets.yaml
   sops updatekeys hosts/cupix001/secrets.yaml
   # ... for each host
   ```
4. Deploy new key to user's machine

### Rotate Host Key

1. Generate new age key for host
2. Update `.sops.yaml` with new public key
3. Re-encrypt that host's secrets:
   ```bash
   sops updatekeys hosts/<hostname>/secrets.yaml
   ```
4. Deploy new private key to host
5. Rebuild: `sudo nixos-rebuild switch --flake .#<hostname>`

### Bulk Re-encryption

```bash
# Re-encrypt all secrets files after key changes
find hosts -name "secrets.yaml" -exec sops updatekeys {} \;
```

---

## 7. Troubleshooting

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Failed to get the data key` | Wrong/missing age key on host | Deploy correct key to `/var/lib/sops-nix/key.txt` |
| `MAC mismatch` | secrets.yaml corrupted or edited without sops | Re-encrypt: `sops -d file | sops -e /dev/stdin > file` |
| `no matching creation rule` | `.sops.yaml` path_regex doesn't match | Check path regex against actual file path |
| `key not found` | Secret referenced but not in secrets.yaml | Add the secret: `sops hosts/<host>/secrets.yaml` |
| `permission denied` on secret path | Wrong `owner`/`mode` in sops config | Check `sops.secrets.<name>.owner` and `.mode` |

### Diagnostic Commands

```bash
# Test decryption locally
sops -d hosts/<hostname>/secrets.yaml

# Check which keys can decrypt a file
sops filestatus hosts/<hostname>/secrets.yaml

# Verify host key is in place
ssh root@host "cat /var/lib/sops-nix/key.txt | head -1"
# Should show: # created: <date>

# Check sops-nix service status
ssh root@host "systemctl status sops-nix"
ssh root@host "ls -la /run/secrets/"

# Check activation log
ssh root@host "journalctl -u sops-nix -b"
```

### Secret Not Available at Boot

If a service starts before sops-nix decrypts:
```nix
systemd.services.<name> = {
  after = [ "sops-nix.service" ];
  requires = [ "sops-nix.service" ];
};
```

### Impermanence + sops-nix

For hosts using impermanence, the age key MUST be persisted:
```nix
environment.persistence."/persist/system".directories = [
  "/var/lib/sops-nix"
];
```

Otherwise the key is lost on reboot and secrets can't be decrypted.

---

## 8. Security Best Practices

- **NEVER** commit plaintext secrets to git
- **NEVER** store age private keys in the nix-config repo
- **ALWAYS** use `sops.secrets.<name>.path` — never hardcode `/run/secrets/` paths
- **ALWAYS** set minimal `mode` permissions (default: `0400`)
- **ALWAYS** set appropriate `owner`/`group` for service secrets
- Use `restartUnits` to auto-restart services when secrets change
- Use `neededForUsers = true` for password secrets (available early in activation)
- Rotate keys when team members leave or hosts are decommissioned
