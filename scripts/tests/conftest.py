"""Pytest configuration for netcup_firewall test suite.

Adds the parent ``scripts/`` directory to ``sys.path`` so that
``import netcup_firewall`` works without installing the package.
"""

from __future__ import annotations

import sys
from pathlib import Path

# Add scripts/ to sys.path so test modules can import netcup_firewall directly.
sys.path.insert(0, str(Path(__file__).parent.parent))
