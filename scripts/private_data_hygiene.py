#!/usr/bin/env python3
"""Guard against recording operational data in the public repository.

Three rules, all run over the *recorded* content (the flake source, the git
index, or an explicit path list):

  value   a line matching one of the operator's operational value classes
  file    a per-host private-value file, or a host module that imports one
  secret  a secrets.y[a]ml without SOPS metadata and ciphertext values

Usage:
    private_data_hygiene.py --tree DIR [DIR ...]   # walk directories
    private_data_hygiene.py FILE [FILE ...]        # scan explicit files

Exit status: 0 when nothing is found, 1 when any finding is reported.

The pattern literals below are written so that this file does not match its own
rules: every operational class is expressed as a regular expression whose text
differs from any value it matches.
"""

from __future__ import annotations

import os
import re
import sys

# (regular expression, human-readable class)
VALUE_PATTERNS: list[tuple[str, str]] = [
    (r"159\.195\.", "edge-host public address"),
    (r"2a0a:4cc0:c1:7d64:844:7ff:fe8a:9ee[3]", "edge-host IPv6 address"),
    (r"0a:44:07:8a:9e:e[3]", "edge-host hardware address"),
    (r"46\.38\.(252|225)\.", "hosting-provider resolver"),
    (r"192\.168\.168\.", "home-LAN subnet"),
    (r"10\.100\.0\.", "WireGuard subnet"),
    (r"55[8]09", "non-standard SSH port"),
]

PRIVATE_VALUE_BASENAMES = {"private.nix", "private.md"}
HOST_MODULE_IMPORT = re.compile(r"^\s*\./private\.nix\s*$", re.MULTILINE)
SECRET_BASENAMES = {"secrets.yaml", "secrets.yml"}
SOPS_METADATA = re.compile(r"^sops:", re.MULTILINE)
CIPHERTEXT = "ENC[AES256_GCM,"
SCALAR_LINE = re.compile(r"^(\s*)([^:#\s][^:]*):(\s*)(.*)$")
LIST_ITEM = re.compile(r"^\s*-\s+(.*)$")

SKIP_DIRS = {".git", "result", "__pycache__", ".direnv"}


def _iter_files(paths: list[str]):
    for path in paths:
        if os.path.isdir(path):
            for root, dirs, names in os.walk(path):
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
                for name in sorted(names):
                    yield os.path.join(root, name)
        else:
            yield path


def _read(path: str) -> str | None:
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except (UnicodeDecodeError, OSError):
        return None


def scan_secret(path: str, content: str) -> list[str]:
    """A secret file must carry SOPS metadata and ciphertext scalar values."""
    findings: list[str] = []
    if not SOPS_METADATA.search(content):
        findings.append(f"{path}: secret file has no SOPS metadata block")
        return findings
    in_metadata = False
    for number, line in enumerate(content.splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if indent == 0:
            in_metadata = stripped.startswith("sops:")
            if in_metadata:
                continue
        if in_metadata:
            continue
        item = LIST_ITEM.match(line)
        if item:
            value = item.group(1).strip()
            if value and not value.startswith(CIPHERTEXT):
                findings.append(
                    f"{path}:{number}: plaintext list value where a SOPS ciphertext is required"
                )
            continue
        match = SCALAR_LINE.match(line)
        if not match:
            continue
        value = match.group(4).strip()
        if value and not value.startswith(CIPHERTEXT):
            findings.append(
                f"{path}:{number}: plaintext value where a SOPS ciphertext is required"
            )
    return findings


def scan_file(path: str, content: str) -> list[str]:
    findings: list[str] = []
    basename = os.path.basename(path)

    if basename in PRIVATE_VALUE_BASENAMES:
        findings.append(f"{path}: per-host private-value file is recorded")

    if basename.endswith(".nix") and HOST_MODULE_IMPORT.search(content):
        findings.append(f"{path}: host module imports ./private.nix")

    if basename in SECRET_BASENAMES:
        findings.extend(scan_secret(path, content))
        return findings

    for number, line in enumerate(content.splitlines(), start=1):
        for pattern, label in VALUE_PATTERNS:
            if re.search(pattern, line):
                findings.append(f"{path}:{number}: {label} is recorded")
    return findings


def main(argv: list[str]) -> int:
    args = argv[1:]
    if not args:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    if args[0] == "--tree":
        args = args[1:]
        if not args:
            print("--tree needs at least one directory", file=sys.stderr)
            return 2
    elif args[0].startswith("--"):
        print(f"unknown option {args[0]}", file=sys.stderr)
        return 2

    findings: list[str] = []
    for path in _iter_files(args):
        content = _read(path)
        if content is None:
            continue
        findings.extend(scan_file(path, content))

    for finding in findings:
        print(f"[private-data-hygiene] {finding}")
    if findings:
        print(f"[private-data-hygiene] {len(findings)} finding(s)")
        return 1
    print("[private-data-hygiene] no operational value, private-value file or plaintext secret recorded")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
