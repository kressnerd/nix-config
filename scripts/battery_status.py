#!/usr/bin/env python3
"""battery-status — the waybar battery module for a machine with several packs.

Waybar's native ``battery`` module resolves a single ``BAT*`` device and falls
back to the aggregate ``battery`` class device, which only exists when one
driver owns every pack. thiniel (an X230) carries two packs from different
drivers, so the native module reports one of them as if it were the machine.
This module reads every pack itself: the bar shows the combined energy, the
tooltip lists each pack with its charge, health and cycles.

It also reads the charge band configured in ``settings/battery-status.json``
and explains an idle pack. auto-cpufreq holds the packs between those
thresholds, so "Not charging" at 21% is the policy working, not a fault.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

DEFAULT_ROOT = Path("/sys/class/power_supply")
POLICY_FILE = Path(__file__).resolve().parent / "settings" / "battery-status.json"

ICON_CHARGING = "󰂄"
ICONS = (
    "󰂎",
    "󰁺",
    "󰁻",
    "󰁼",
    "󰁽",
    "󰁾",
    "󰁿",
    "󰂀",
    "󰂁",
    "󰂂",
    "󰁹",
)
WARNING_PERCENT = 30
CRITICAL_PERCENT = 15
SEPARATOR = "\u2500" * 24
CHARGING_STATES = frozenset({"charging", "full"})
IDLE_STATES = frozenset({"not charging", "full"})


@dataclass(frozen=True)
class Battery:
    """One power pack, as read from its ``/sys/class/power_supply`` entry."""

    name: str
    model: str | None
    manufacturer: str | None
    energy_now: int
    energy_full: int
    energy_full_design: int | None
    status: str
    cycle_count: int | None
    technology: str | None

    @property
    def charging(self) -> bool:
        return self.status.lower() in CHARGING_STATES

    @property
    def percent(self) -> int:
        if self.energy_full <= 0:
            return 0
        return min(100, round(100 * self.energy_now / self.energy_full))

    @property
    def health(self) -> int | None:
        if not self.energy_full_design:
            return None
        return min(100, round(100 * self.energy_full / self.energy_full_design))


@dataclass(frozen=True)
class ThresholdPolicy:
    """The charge band handed to the battery driver by auto-cpufreq."""

    start: int
    stop: int


def _read(directory: Path, key: str) -> str | None:
    try:
        return (directory / key).read_text().strip()
    except OSError:
        return None


def _read_int(directory: Path, key: str) -> int | None:
    raw = _read(directory, key)
    if raw is None:
        return None
    try:
        return int(raw)
    except ValueError:
        return None


def _energy(directory: Path, energy_key: str, charge_key: str) -> int | None:
    """Energy in µWh.

    Some packs report charge (µAh) instead of energy (µWh); those are scaled
    by the current voltage. Where the current voltage is not exposed the
    design voltage stands in, which is an approximation on a worn pack.
    """
    value = _read_int(directory, energy_key)
    if value is not None:
        return value
    charge = _read_int(directory, charge_key)
    voltage = _read_int(directory, "voltage_now")
    if voltage is None:
        voltage = _read_int(directory, "voltage_min_design")
    if charge is None or voltage is None:
        return None
    return charge * voltage // 1_000_000


def read_batteries(root: Path = DEFAULT_ROOT) -> list[Battery]:
    """Return every pack under ``root``, ordered by device name."""
    batteries: list[Battery] = []
    try:
        entries = sorted(root.iterdir())
    except OSError:
        return []

    for directory in entries:
        if not directory.is_dir():
            continue
        energy_now = _energy(directory, "energy_now", "charge_now")
        energy_full = _energy(directory, "energy_full", "charge_full")
        if energy_now is None or energy_full is None:
            continue

        batteries.append(
            Battery(
                name=directory.name,
                model=_read(directory, "model_name"),
                manufacturer=_read(directory, "manufacturer"),
                energy_now=energy_now,
                energy_full=energy_full,
                energy_full_design=_read_int(directory, "energy_full_design"),
                status=_read(directory, "status") or "Unknown",
                cycle_count=_read_int(directory, "cycle_count"),
                technology=_read(directory, "technology"),
            )
        )
    return batteries


def combined_percent(batteries: Sequence[Battery]) -> int:
    """Charge left across all packs, weighted by capacity."""
    full = sum(b.energy_full for b in batteries)
    if full <= 0:
        return 0
    now = sum(b.energy_now for b in batteries)
    return max(0, min(100, round(100 * now / full)))


def overall_charging(batteries: Sequence[Battery]) -> bool:
    return bool(batteries) and all(b.charging for b in batteries)


def policy(path: Path | None = None) -> ThresholdPolicy | None:
    if path is None:
        path = Path(os.environ.get("BATTERY_STATUS_POLICY", POLICY_FILE))
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError):
        return None
    try:
        return ThresholdPolicy(start=int(data["start"]), stop=int(data["stop"]))
    except (KeyError, TypeError, ValueError):
        return None


def held_by_threshold(
    batteries: Sequence[Battery], band: ThresholdPolicy | None
) -> bool:
    """True when packs sit idle because the band is holding them there.

    One pack charging means auto-cpufreq is in control. A pack that reports
    itself idle while inside the band is held there -- at the start level
    until it recovers, or wherever it sat when the band was lowered.
    """
    if band is None:
        return False
    if not any(b.charging for b in batteries):
        return False
    return any(
        b.status.lower() in IDLE_STATES and band.start <= b.percent <= band.stop
        for b in batteries
    )


def _wh(microwatt_hours: int) -> str:
    return f"{microwatt_hours / 1_000_000:.2f} Wh"


def _escape(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _battery_lines(battery: Battery) -> list[str]:
    label = " ".join(part for part in (battery.manufacturer, battery.model) if part)
    heading = battery.name if not label else f"{battery.name} · {label}"
    details = [
        f"{battery.percent}%",
        _escape(battery.status),
        f"{_wh(battery.energy_now)} / {_wh(battery.energy_full)}",
    ]
    health = battery.health
    if health is not None:
        details.append(f"health {health}%")
    if battery.cycle_count is not None:
        details.append(f"{battery.cycle_count} cycles")
    if battery.technology:
        details.append(_escape(battery.technology))
    return [
        f"<b>{_escape(heading)}</b>",
        " · ".join(details),
    ]


def tooltip(batteries: Sequence[Battery], band: ThresholdPolicy | None = None) -> str:
    if not batteries:
        return "No battery detected"

    # Pack fields are escaped where they enter; the markup below is ours.
    lines: list[str] = []
    for battery in batteries:
        if lines:
            lines.append(SEPARATOR)
        lines.extend(_battery_lines(battery))

    now = sum(b.energy_now for b in batteries)
    full = sum(b.energy_full for b in batteries)
    states = sorted({b.status for b in batteries})
    lines += [
        SEPARATOR,
        f"<b>Total</b> {combined_percent(batteries)}% · {_wh(now)} / {_wh(full)}",
    ]
    if len(states) > 1:
        lines.append("State: " + ", ".join(_escape(s) for s in states))

    if band is not None and held_by_threshold(batteries, band):
        lines.append(
            f"Threshold: auto-cpufreq limits the charge band to "
            f"{band.start}–{band.stop}%, so a full pack stays idle by design."
        )
    return "\n".join(lines)


def _state_class(percent: int, charging: bool) -> str:
    if charging:
        return "charging"
    if percent <= CRITICAL_PERCENT:
        return "critical"
    if percent <= WARNING_PERCENT:
        return "warning"
    return "discharging"


def render(batteries: Sequence[Battery], band: ThresholdPolicy | None = None) -> str:
    """Waybar JSON payload for the ``custom/battery`` module."""
    if not batteries:
        return json.dumps(
            {"text": "no battery", "class": "battery empty", "tooltip": tooltip([])}
        )

    percent = combined_percent(batteries)
    charging = overall_charging(batteries)
    if charging:
        text = f"{ICON_CHARGING} {percent}%"
    else:
        text = f"{ICONS[min(len(ICONS) - 1, percent * len(ICONS) // 100)]} {percent}%"
    return json.dumps(
        {
            "text": text,
            "percentage": percent,
            "class": f"battery {_state_class(percent, charging)}",
            "tooltip": tooltip(batteries, band),
        }
    )


def format_plain(
    batteries: Sequence[Battery], band: ThresholdPolicy | None = None
) -> str:
    """Human-readable report; the waybar tooltip without the markup."""
    text = tooltip(batteries, band).replace("<b>", "").replace("</b>", "")
    return text.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Print the waybar battery module payload for every battery pack."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=DEFAULT_ROOT,
        help=f"power_supply directory (default: {DEFAULT_ROOT})",
    )
    parser.add_argument(
        "--policy",
        type=Path,
        default=POLICY_FILE,
        help=f"charge-band file (default: {POLICY_FILE})",
    )
    parser.add_argument(
        "--plain",
        action="store_true",
        help="print the tooltip as text instead of the waybar JSON payload",
    )
    args = parser.parse_args(argv)

    batteries = read_batteries(args.root)
    band = policy(args.policy)
    if args.plain:
        print(format_plain(batteries, band))
    else:
        print(render(batteries, band))
    return 0


if __name__ == "__main__":
    sys.exit(main())
