# Security Policy

## Reporting a vulnerability

Report vulnerabilities through [Private Vulnerability Reporting](https://github.com/kressnerd/nix-config/security/advisories/new), not in a public issue.

Include the affected file or workflow, the host or output it influences, and the smallest reproduction you can share. Do not include live credentials or decrypted secret values.

## Scope

- NixOS, nix-darwin and Home Manager modules under `modules/`, `hosts/` and `home/`
- Flake inputs, overlays and evaluation-time assertions under `flake.nix`, `overlays/` and `tests/`
- GitHub Actions workflows under `.github/workflows/`
- The secret-hygiene and license rules (`scripts/private_data_hygiene.py`, `.gitleaks.toml`, `REUSE.toml`)

## Out of scope

- Secrets that are intentionally committed in encrypted form (`hosts/*/secrets.yaml`, age/sops ciphertext). Ciphertext in the repository is expected; a usable decryption key in the repository is in scope.
- Vulnerabilities in upstream packages that the repository only pins. Report those upstream; report here if the pin selection defeats a documented invariant.
- Findings that require write access to the repository or to a deployed host.

## Response

A report is acknowledged within 14 days. A fix or a documented decision is the goal; coordinated disclosure happens after the fix lands.
