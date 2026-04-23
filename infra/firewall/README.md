# Firewall Policy Definitions

Infrastructure-as-code definitions for netcup SCP external firewall policies.

## Policy Files

| File | Purpose | Lifecycle |
|------|---------|-----------|
| `lockdown.json` | Block all traffic (explicit DROP rules for TCP/UDP/ICMP/ICMPv6) | Persistent — shared across servers |

## Format

Each JSON file defines a named firewall policy:

```json
{
  "name": "policy-name",
  "description": "Human-readable description",
  "rules": [
    {
      "direction": "INGRESS",
      "protocol": "TCP",
      "sourceIp": "0.0.0.0/0",
      "destinationPort": "443",
      "action": "ACCEPT"
    }
  ]
}
```

### Rule Fields

| Field | Values | Required |
|-------|--------|----------|
| `direction` | `INGRESS` | Yes |
| `protocol` | `TCP`, `UDP` | Yes |
| `sourceIp` | CIDR notation (e.g., `0.0.0.0/0`) | Yes |
| `destinationPort` | Port number as string (e.g., `"443"`) | Yes |
| `action` | `ACCEPT` | Yes |

### Limitations

- No `protocol: ANY` for non-reseller netcup accounts
- Implicit rules (`ingressImplicitRule: DROP`) cannot be disabled
- Lockdown policy uses explicit DROP rules for TCP, UDP, ICMP, and ICMPv6 to block all inbound traffic

## Usage

Policies are managed via `scripts/netcup_firewall.py`:

```bash
# Apply a policy (Epic 15 — not yet implemented)
python3 scripts/netcup_firewall.py apply --server cupix001 --policy lockdown
```

## Security

Policy definitions are **not secret** — they describe port rules, not credentials.
Source IPs in policy rules may reveal operator IP ranges — use `0.0.0.0/0` for public rules.
