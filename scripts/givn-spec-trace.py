#!/usr/bin/env python3
"""Traceability check for givn delta specs.

Every Gherkin scenario in a change delta MUST carry exactly one binding tag
naming the native verification target that proves it:

    @check:<name>    a flake check    -> nix build .#checks.<system>.<name>
    @host:<name>     a host config    -> nix eval .#<kind>Configurations.<name>.config.system.build.toplevel.drvPath
    @deploy:<name>   a deploy test    -> pytest tests/deploy/test_<name>.py against a live host

Scenarios tagged @e2e (real-interface smoke tests) MUST bind to a VM
integration check (@check:integration-*), a host, or a deploy test.

Exit status: 0 when every scenario is bound to an existing target, 1 otherwise.
This is the substitute for a repository-wide coverage metric: the mapping from
scenario to executable target is the coverage evidence.
"""

from __future__ import annotations

import glob
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIND_RE = re.compile(r"^@(check|host|deploy):([A-Za-z0-9_.\-]+)$")
SCENARIO_RE = re.compile(r"^\s*(Scenario Outline|Scenario|Example)\s*:\s*(.*)$")


def nix_eval_json(expr: str, flakeref: str) -> list[str]:
    try:
        proc = subprocess.run(
            ["nix", "eval", "--json", flakeref, "--apply", expr],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(proc.stdout)
    except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError):
        return []


def check_names() -> set[str]:
    names: set[str] = set()
    for system in nix_eval_json("x: builtins.attrNames x", ".#checks"):
        names.update(nix_eval_json("x: builtins.attrNames x", f".#checks.{system}"))
    return names


def host_names() -> set[str]:
    names: set[str] = set()
    for output in ("nixosConfigurations", "darwinConfigurations"):
        names.update(nix_eval_json("x: builtins.attrNames x", f".#{output}"))
    return names


def feature_files() -> list[str]:
    patterns = [
        os.path.join(ROOT, "givn", "changes", "*", "specs", "**", "*.feature"),
        os.path.join(ROOT, "givn", "specs", "**", "*.feature"),
    ]
    files: set[str] = set()
    for pattern in patterns:
        files.update(glob.glob(pattern, recursive=True))
    return sorted(files)


def scenarios(path: str):
    """Yield (line_number, title, tags) for each scenario in a .feature file."""
    pending: list[str] = []
    with open(path, encoding="utf-8") as handle:
        for lineno, raw in enumerate(handle, start=1):
            line = raw.strip()
            if not line:
                pending = []
                continue
            if line.startswith("#"):
                continue
            if line.startswith("@"):
                pending.extend(line.split())
                continue
            match = SCENARIO_RE.match(line)
            if match:
                yield lineno, match.group(2).strip(), list(pending)
            pending = []


def rel(path: str) -> str:
    return os.path.relpath(path, ROOT)


def main() -> int:
    checks = check_names()
    hosts = host_names()
    files = feature_files()

    findings: list[str] = []
    warnings: list[str] = []
    referenced_checks: set[str] = set()
    scenario_count = 0

    for path in files:
        where = rel(path)
        for lineno, title, tags in scenarios(path):
            scenario_count += 1
            label = f"{where}:{lineno}: scenario '{title}'"
            bindings = [m.groups() for t in tags if (m := BIND_RE.match(t))]
            e2e = "@e2e" in tags

            if len(bindings) != 1:
                findings.append(
                    f"{label} has {len(bindings)} binding tag(s); "
                    "expected exactly one of @check:<name>, @host:<name>, @deploy:<name>"
                )
                continue

            kind, name = bindings[0]
            if kind == "check":
                referenced_checks.add(name)
                if name not in checks:
                    findings.append(
                        f"{label} binds @check:{name}, which is not a check in "
                        "the flake (see `nix flake show`)"
                    )
                elif e2e and not name.startswith("integration-"):
                    findings.append(
                        f"{label} is @e2e but binds @check:{name}; an @e2e "
                        "scenario must bind to a VM integration check "
                        "(@check:integration-*) or @host:/@deploy:"
                    )
            elif kind == "host":
                if name not in hosts:
                    findings.append(
                        f"{label} binds @host:{name}, which is not a "
                        "nixosConfigurations/darwinConfigurations entry"
                    )
            else:  # deploy
                candidate = os.path.join(ROOT, "tests", "deploy", f"test_{name}.py")
                if not os.path.exists(candidate):
                    findings.append(
                        f"{label} binds @deploy:{name}, but {rel(candidate)} does not exist"
                    )

    for name in sorted(c for c in checks if c.startswith("integration-") and c not in referenced_checks):
        warnings.append(f"integration check '{name}' is not referenced by any scenario")

    for finding in findings:
        print(f"[FAIL] {finding}")
    for warning in warnings:
        print(f"[warn] {warning}")
    print(
        f"givn-spec-trace: {scenario_count} scenario(s) across {len(files)} feature file(s), "
        f"{len(findings)} finding(s)"
    )
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
