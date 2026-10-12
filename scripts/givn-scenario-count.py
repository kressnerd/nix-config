#!/usr/bin/env python3
"""Count the scenarios in the repository's feature files, split by scope.

The givn runner contract (0.7.0) requires each scope command to write real
scenario counts to `$GIVN_RESULT_FILE`, never a hardcoded number. This
repository's scenarios are Gherkin deltas and permanent specs bound to native
Nix targets, so the count comes from the `.feature` files themselves:

    --scope regular   scenarios that are not tagged @e2e
    --scope e2e       scenarios tagged @e2e

Usage: givn-scenario-count.py --scope regular|e2e
"""

from __future__ import annotations

import argparse
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCENARIO_RE = re.compile(r"^\s*(Scenario Outline|Scenario|Example)\s*:")


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
    """Yield (title, tags) for each scenario, tags being the pending tag lines."""
    pending: list[str] = []
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()
            if not line or line.startswith("#"):
                pending = []
                continue
            if line.startswith("@"):
                pending.extend(line.split())
                continue
            match = SCENARIO_RE.match(line)
            if match:
                yield match.group(1).strip(), list(pending)
            pending = []


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scope", choices=["regular", "e2e"], required=True)
    args = parser.parse_args(argv[1:])

    count = 0
    for path in feature_files():
        for _title, tags in scenarios(path):
            is_e2e = "@e2e" in tags
            if (args.scope == "e2e") == is_e2e:
                count += 1
    print(count)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
