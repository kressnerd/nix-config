# Python Nix Integration — All Python dependencies and tooling are managed exclusively via Nix

## Rule ID: PY-NIX-001

**Priority**: MANDATORY  
**Applies to**: All Python dependencies, packaging, and tooling in this repository

## Relationship to Existing Rules

This rule extends [`.roo/rules/10-nix-senior-admin.md`](10-nix-senior-admin.md) (imperative→declarative mappings) and [`.roo/rules/11-repository-conventions.md`](11-repository-conventions.md) (devShell conventions) with Python-specific Nix integration requirements.

## Dependency Management

- Python dependencies are managed **exclusively via Nix** (`python3.withPackages` or `buildPythonApplication` in the flake).
- No `pip install`, no `pip install -g`, no `pip install --user`.
- No `virtualenv`, no `venv`, no `.venv/` directories.
- No `requirements.txt`, no `setup.py`, no `pyproject.toml` for dependency declaration (`pyproject.toml` MAY exist for tool configuration such as `ruff` or `mypy`, but NOT for dependency management).

## uv Prohibition

- `uv` is installed on this system as **MCP server runtime only**.
- `uv` MUST NOT be used for custom Python scripts or tooling.
- Prohibited commands: `uv init`, `uv add`, `uv run`, `uv sync`, `uv pip install`.
- The only allowed `uv` usage is MCP server execution managed outside this repository.

## CLI Script Packaging

- CLI scripts are wrapped as Nix packages using `writeShellApplication` or `buildPythonApplication`.
- Wrapped scripts are available in the system PATH via `environment.systemPackages` or `home.packages`.
- Script sources live in `scripts/`. Nix packaging definitions live in `pkgs/` or inline in `flake.nix`.

## devShell Requirements

- The `devShell` in `flake.nix` includes all Python development dependencies.
- Required devShell packages: `python3`, `python3Packages.requests`, `python3Packages.pytest`, `python3Packages.mypy`, `ruff`.
- Optional devShell packages (add when needed): `python3Packages.hypothesis`, `python3Packages.pytest-mock`, `python3Packages.responses`.
- Enter the shell with `nix develop`. All Python tooling runs inside this shell.

## Secrets and Credentials

- No hardcoded credentials in Python source files.
- API keys and tokens via environment variables or sops-nix/agenix managed secrets.
- Credential files (e.g., OAuth tokens) stored in `~/.config/<tool>/` with `0o600` permissions.
- Credential directories created with `0o700` permissions.
- Never commit credential files to git.

## Anti-Patterns

| Anti-Pattern | Correct Alternative |
|---|---|
| `pip install requests` | Add `python3Packages.requests` to devShell |
| `uv add click` | Add `python3Packages.click` to devShell |
| `python -m venv .venv` | Use `nix develop` |
| `requirements.txt` | Nix devShell `nativeBuildInputs` |
| `uv run script.py` | `python3 script.py` inside `nix develop` |
| Hardcoded API key in source | Environment variable or sops-nix secret |
