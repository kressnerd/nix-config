#!/usr/bin/env python3
"""wifi-menu — choose a Wi-Fi network from the waybar network module.

The bar's network icon runs this script. It asks NetworkManager for the
visible access points, shows them in fuzzel, and connects the selected one,
prompting for the password when NetworkManager has no saved profile for it.
Result and failures are reported through the notification daemon (mako).

The GUI-facing commands are resolved from environment variables so the menu
can be exercised with stand-ins; ``--list`` prints the menu without showing
fuzzel.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from typing import Sequence

SCAN_FIELDS = "IN-USE,SSID,SIGNAL,SECURITY"
CONNECT_TIMEOUT_SECONDS = "30"
ACTIVE_MARKER = "● "
INACTIVE_MARKER = "  "


@dataclass(frozen=True)
class WifiNetwork:
    """One access point as reported by ``nmcli device wifi list``."""

    ssid: str
    signal: int
    security: str
    in_use: bool

    @property
    def open(self) -> bool:
        return self.security == ""


def unescape_terse(value: str) -> str:
    """Undo nmcli's terse-mode escaping of ``:`` and ``\\``.

    Other backslash sequences are not escape sequences in terse output and
    stay as written.
    """
    out: list[str] = []
    index = 0
    while index < len(value):
        char = value[index]
        if char == "\\" and index + 1 < len(value) and value[index + 1] in ":\\":
            out.append(value[index + 1])
            index += 2
            continue
        out.append(char)
        index += 1
    return "".join(out)


def parse_scan(output: str) -> list[WifiNetwork]:
    """Parse ``nmcli --terse --mode multiline`` output into access points.

    The multiline mode keys every value, so an SSID may itself contain a
    colon without breaking the field boundaries. Hidden networks (empty
    SSID) are dropped because fuzzel cannot show a name for them.
    """
    networks: list[WifiNetwork] = []
    fields: dict[str, str] = {}

    def flush() -> None:
        nonlocal fields
        ssid = fields.get("SSID", "")
        if ssid:
            try:
                signal = int(fields.get("SIGNAL", "0"))
            except ValueError:
                signal = 0
            security = fields.get("SECURITY", "").strip()
            if security == "--":
                security = ""
            networks.append(
                WifiNetwork(
                    ssid=ssid,
                    signal=signal,
                    security=security,
                    in_use=fields.get("IN-USE", "").strip() == "*",
                )
            )
        fields = {}

    for raw_line in output.splitlines():
        line = raw_line.rstrip("\r")
        if not line.strip():
            if fields:
                flush()
            continue
        key, separator, value = line.partition(":")
        if not separator:
            continue
        key = key.strip().upper()
        # nmcli separates access points by repeating the first requested
        # field; blank lines are optional.
        if key in fields:
            flush()
        # Leading and trailing spaces are legal in an SSID, so they are kept;
        # every other field is trimmed.
        fields[key] = unescape_terse(value if key == "SSID" else value.strip())
    if fields:
        flush()
    return networks


def merge_networks(networks: Sequence[WifiNetwork]) -> list[WifiNetwork]:
    """Collapse the per-BSSID rows into one entry per SSID.

    A mesh or multi-radio network reports one row per access point. Keep the
    strongest signal and remember whether any row was the active connection.
    """
    by_ssid: dict[str, WifiNetwork] = {}
    for network in networks:
        previous = by_ssid.get(network.ssid)
        if previous is None:
            by_ssid[network.ssid] = network
            continue
        by_ssid[network.ssid] = WifiNetwork(
            ssid=network.ssid,
            signal=max(previous.signal, network.signal),
            security=previous.security or network.security,
            in_use=previous.in_use or network.in_use,
        )
    return sorted(
        by_ssid.values(),
        key=lambda network: (not network.in_use, -network.signal, network.ssid.casefold()),
    )


def menu_entries(networks: Sequence[WifiNetwork]) -> list[str]:
    """Render the fuzzel lines, marking the active network."""
    return [
        f"{ACTIVE_MARKER if network.in_use else INACTIVE_MARKER}{network.ssid}"
        for network in networks
    ]


def selected_network(choice: str, networks: Sequence[WifiNetwork]) -> WifiNetwork | None:
    """Map a fuzzel line back to its network."""
    for entry, network in zip(menu_entries(networks), networks):
        if entry == choice:
            return network
    return None


def needs_password(network: WifiNetwork, saved_names: Sequence[str]) -> bool:
    return not network.open and network.ssid not in saved_names


def connect_args(ssid: str, password: str | None) -> list[str]:
    args = ["--wait", CONNECT_TIMEOUT_SECONDS, "device", "wifi", "connect", ssid]
    if password:
        args += ["password", password]
    return args


def _command(env_var: str, name: str) -> str:
    override = os.environ.get(env_var)
    if override:
        return override
    found = shutil.which(name)
    if found is None:
        raise FileNotFoundError(f"{name} is not installed and {env_var} is unset")
    return found


def _nmcli() -> str:
    return _command("WIFI_MENU_NMCLI", "nmcli")


def _fuzzel_bin() -> str:
    return _command("WIFI_MENU_FUZZEL", "fuzzel")


def _notify_bin() -> str | None:
    override = os.environ.get("WIFI_MENU_NOTIFY")
    if override:
        return override
    return shutil.which("notify-send")


def _run(args: Sequence[str], stdin: str | None = None) -> str:
    completed = subprocess.run(
        list(args),
        input=stdin,
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        message = (completed.stderr or completed.stdout).strip()
        raise RuntimeError(message or f"{args[0]} exited with {completed.returncode}")
    return completed.stdout


def notify(message: str, urgency: str = "normal") -> None:
    binary = _notify_bin()
    if binary is None:
        return
    try:
        subprocess.run(
            [binary, "--app-name=Wi-Fi", f"--urgency={urgency}", message],
            check=False,
            capture_output=True,
        )
    except OSError:
        # A missing notification daemon must not turn a dialog into a crash.
        pass


def scan() -> list[WifiNetwork]:
    output = _run(
        [
            _nmcli(),
            "--terse",
            "--mode",
            "multiline",
            "--fields",
            SCAN_FIELDS,
            "device",
            "wifi",
            "list",
        ]
    )
    return merge_networks(parse_scan(output))


def saved_connection_names() -> list[str]:
    output = _run([_nmcli(), "--terse", "--fields", "NAME,TYPE", "connection", "show"])
    names: list[str] = []
    for line in output.splitlines():
        name, separator, kind = line.rpartition(":")
        if separator and kind.strip() == "802-11-wireless":
            names.append(unescape_terse(name))
    return names


def fuzzel(entries: Sequence[str], prompt: str, password: bool = False) -> str | None:
    """Show a fuzzel menu and return the selection, or None when dismissed."""
    args = [_fuzzel_bin(), "--dmenu", f"--prompt={prompt}"]
    if password:
        args.append("--password")
    stdin = "\n".join(entries)
    if stdin:
        stdin += "\n"
    completed = subprocess.run(
        args,
        input=stdin,
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        return None
    return completed.stdout.rstrip("\n") or None


def connect(ssid: str, password: str | None) -> None:
    _run([_nmcli(), *connect_args(ssid, password)])


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Pick and join a Wi-Fi network.")
    parser.add_argument(
        "--list",
        action="store_true",
        help="print the menu entries instead of showing fuzzel",
    )
    args = parser.parse_args(argv)

    try:
        networks = scan()
    except (RuntimeError, OSError) as error:
        notify(f"Wi-Fi scan failed: {error}", "critical")
        return 1

    entries = menu_entries(networks)
    if args.list:
        print("\n".join(entries))
        return 0
    if not entries:
        notify("No Wi-Fi networks found")
        return 0

    try:
        choice = fuzzel(entries, "Wi-Fi ")
    except OSError as error:
        notify(f"Wi-Fi chooser failed: {error}", "critical")
        return 1
    if choice is None:
        return 0
    network = selected_network(choice, networks)
    if network is None:
        return 0
    if network.in_use:
        notify(f"Already connected to {network.ssid}")
        return 0
    if "802.1X" in network.security:
        notify(
            f"{network.ssid} needs enterprise credentials and cannot be joined from the bar",
            "critical",
        )
        return 1

    try:
        saved = saved_connection_names()
    except (RuntimeError, OSError):
        # Unable to read the profiles; asking for a password is harmless and
        # keeps a secured network reachable.
        saved = []

    password: str | None = None
    if needs_password(network, saved):
        try:
            password = fuzzel([], f"Password for {network.ssid} ", password=True)
        except OSError as error:
            notify(f"Wi-Fi chooser failed: {error}", "critical")
            return 1
        if not password:
            return 0

    try:
        connect(network.ssid, password)
    except (RuntimeError, OSError) as error:
        notify(f"Could not connect to {network.ssid}: {error}", "critical")
        return 1
    notify(f"Connected to {network.ssid}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
