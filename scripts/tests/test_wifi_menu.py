"""Behavioural tests for the waybar Wi-Fi chooser (scripts/wifi_menu.py)."""

from __future__ import annotations

from typing import Any

import pytest

import wifi_menu
from wifi_menu import (
    WifiNetwork,
    connect_args,
    menu_entries,
    merge_networks,
    needs_password,
    parse_scan,
    selected_network,
    unescape_terse,
)

SAMPLE_SCAN = """IN-USE: 
SSID:Spinnennetz
SIGNAL:100
SECURITY:WPA2 WPA3
IN-USE: 
SSID:Hasenbau
SIGNAL:100
SECURITY:WPA2 WPA3
IN-USE:*
SSID:Hasenbau
SIGNAL:89
SECURITY:WPA2 WPA3
IN-USE: 
SSID:Cafe
SIGNAL:42
SECURITY:
IN-USE: 
SSID:Office
SIGNAL:70
SECURITY:WPA2 802.1X
"""


class TestParseScan:
    def test_parses_each_access_point(self) -> None:
        networks = parse_scan(SAMPLE_SCAN)
        assert [(n.ssid, n.signal, n.in_use) for n in networks] == [
            ("Spinnennetz", 100, False),
            ("Hasenbau", 100, False),
            ("Hasenbau", 89, True),
            ("Cafe", 42, False),
            ("Office", 70, False),
        ]

    def test_open_network_has_empty_security(self) -> None:
        cafe = next(n for n in parse_scan(SAMPLE_SCAN) if n.ssid == "Cafe")
        assert cafe.security == ""
        assert cafe.open

    def test_ssid_may_contain_colon(self) -> None:
        output = "IN-USE:\nSSID:My\\:Net\nSIGNAL:55\nSECURITY:WPA2\n"
        assert parse_scan(output)[0].ssid == "My:Net"

    def test_hidden_network_is_dropped(self) -> None:
        output = "IN-USE:\nSSID:\nSIGNAL:10\nSECURITY:WPA2\n"
        assert parse_scan(output) == []

    def test_legacy_open_marker_becomes_empty(self) -> None:
        output = "IN-USE:\nSSID:Open\nSIGNAL:10\nSECURITY:--\n"
        assert parse_scan(output)[0].security == ""

    def test_trailing_block_without_blank_line_is_kept(self) -> None:
        output = "IN-USE:\nSSID:Last\nSIGNAL:12\nSECURITY:WPA2"
        assert [n.ssid for n in parse_scan(output)] == ["Last"]


class TestUnescapeTerse:
    def test_unescapes_colon_and_backslash(self) -> None:
        assert unescape_terse(r"My\:Net\\2") == r"My:Net\2"


class TestMergeNetworks:
    def test_collapses_duplicate_bssids_and_keeps_active_and_strongest(self) -> None:
        merged = merge_networks(parse_scan(SAMPLE_SCAN))
        hasenbau = next(n for n in merged if n.ssid == "Hasenbau")
        assert hasenbau.signal == 100
        assert hasenbau.in_use

    def test_orders_active_first_then_signal_descending(self) -> None:
        merged = merge_networks(parse_scan(SAMPLE_SCAN))
        assert [n.ssid for n in merged] == ["Hasenbau", "Spinnennetz", "Office", "Cafe"]


class TestMenu:
    def test_marks_active_network(self) -> None:
        networks = merge_networks(parse_scan(SAMPLE_SCAN))
        assert menu_entries(networks)[0] == "● Hasenbau"
        assert menu_entries(networks)[1] == "  Spinnennetz"

    def test_active_marker_in_ssid_still_maps_back(self) -> None:
        networks = [WifiNetwork(ssid="● WLAN", signal=5, security="", in_use=False)]
        choice = menu_entries(networks)[0]
        assert selected_network(choice, networks) == networks[0]

    def test_unknown_choice_maps_to_none(self) -> None:
        assert selected_network("  nope", []) is None


class TestPasswordPolicy:
    def test_open_network_never_needs_password(self) -> None:
        network = WifiNetwork(ssid="Cafe", signal=40, security="", in_use=False)
        assert not needs_password(network, [])

    def test_secured_network_with_saved_profile_needs_no_password(self) -> None:
        network = WifiNetwork(ssid="Home", signal=40, security="WPA2", in_use=False)
        assert not needs_password(network, ["Home"])

    def test_secured_network_without_profile_needs_password(self) -> None:
        network = WifiNetwork(ssid="Home", signal=40, security="WPA2", in_use=False)
        assert needs_password(network, ["Cafe"])


class TestConnectArgs:
    def test_includes_password_only_when_given(self) -> None:
        assert connect_args("Home", "secret") == [
            "--wait",
            "30",
            "device",
            "wifi",
            "connect",
            "Home",
            "password",
            "secret",
        ]
        assert connect_args("Cafe", None) == [
            "--wait",
            "30",
            "device",
            "wifi",
            "connect",
            "Cafe",
        ]


@pytest.fixture
def menu(monkeypatch: pytest.MonkeyPatch) -> Any:
    """Stand in for the external programs and record their interaction."""

    class Menu:
        def __init__(self) -> None:
            self.networks = merge_networks(parse_scan(SAMPLE_SCAN))
            self.saved: list[str] = []
            self.notifications: list[tuple[str, str]] = []
            self.fuzzel_calls: list[tuple[list[str], str, bool]] = []
            self.answers: list[str | None] = []
            self.connected: list[tuple[str, str | None]] = []
            self.scan_error: Exception | None = None
            self.connect_error: Exception | None = None

            monkeypatch.setattr(wifi_menu, "scan", self.scan)
            monkeypatch.setattr(wifi_menu, "saved_connection_names", lambda: self.saved)
            monkeypatch.setattr(wifi_menu, "notify", self.record_notification)
            monkeypatch.setattr(wifi_menu, "fuzzel", self.fuzzel)
            monkeypatch.setattr(wifi_menu, "connect", self.connect)

        def scan(self) -> list[WifiNetwork]:
            if self.scan_error is not None:
                raise self.scan_error
            return self.networks

        def record_notification(self, message: str, urgency: str = "normal") -> None:
            self.notifications.append((message, urgency))

        def fuzzel(self, entries: list[str], prompt: str, password: bool = False) -> str | None:
            self.fuzzel_calls.append((list(entries), prompt, password))
            return self.answers.pop(0) if self.answers else None

        def connect(self, ssid: str, password: str | None) -> None:
            if self.connect_error is not None:
                raise self.connect_error
            self.connected.append((ssid, password))

    return Menu()


class TestMain:
    def test_list_prints_entries_without_fuzzel(self, menu: Any, capsys: pytest.CaptureFixture[str]) -> None:
        assert wifi_menu.main(["--list"]) == 0
        out = capsys.readouterr().out.splitlines()
        assert out == ["● Hasenbau", "  Spinnennetz", "  Office", "  Cafe"]
        assert menu.fuzzel_calls == []

    def test_dismissed_menu_connects_nothing(self, menu: Any) -> None:
        menu.answers = [None]
        assert wifi_menu.main([]) == 0
        assert menu.connected == []
        assert menu.notifications == []

    def test_connects_open_network_without_password_prompt(self, menu: Any) -> None:
        menu.answers = ["  Cafe"]
        assert wifi_menu.main([]) == 0
        assert menu.connected == [("Cafe", None)]
        assert [call[2] for call in menu.fuzzel_calls] == [False]
        assert menu.notifications == [("Connected to Cafe", "normal")]

    def test_saved_profile_connects_without_password_prompt(self, menu: Any) -> None:
        menu.answers = ["  Spinnennetz"]
        menu.saved = ["Spinnennetz"]
        assert wifi_menu.main([]) == 0
        assert menu.connected == [("Spinnennetz", None)]
        assert [call[2] for call in menu.fuzzel_calls] == [False]

    def test_unsaved_secured_network_prompts_for_password(self, menu: Any) -> None:
        menu.answers = ["  Spinnennetz", "secret"]
        assert wifi_menu.main([]) == 0
        assert menu.connected == [("Spinnennetz", "secret")]
        assert menu.fuzzel_calls[1] == ([], "Password for Spinnennetz ", True)

    def test_empty_password_aborts_connection(self, menu: Any) -> None:
        menu.answers = ["  Spinnennetz", None]
        assert wifi_menu.main([]) == 0
        assert menu.connected == []

    def test_active_network_is_reported_not_reconnected(self, menu: Any) -> None:
        menu.answers = ["● Hasenbau"]
        assert wifi_menu.main([]) == 0
        assert menu.connected == []
        assert menu.notifications == [("Already connected to Hasenbau", "normal")]

    def test_enterprise_network_is_rejected_with_guidance(self, menu: Any) -> None:
        menu.answers = ["  Office"]
        assert wifi_menu.main([]) == 1
        assert menu.connected == []
        assert "enterprise" in menu.notifications[0][0]

    def test_scan_failure_is_reported(self, menu: Any) -> None:
        menu.scan_error = RuntimeError("wlan0 not found")
        assert wifi_menu.main([]) == 1
        assert menu.notifications == [("Wi-Fi scan failed: wlan0 not found", "critical")]

    def test_connect_failure_is_reported(self, menu: Any) -> None:
        menu.answers = ["  Cafe"]
        menu.connect_error = RuntimeError("Connection activation failed")
        assert wifi_menu.main([]) == 1
        assert menu.notifications == [
            ("Could not connect to Cafe: Connection activation failed", "critical")
        ]

    def test_no_visible_networks_is_reported_without_menu(self, menu: Any) -> None:
        menu.networks = []
        assert wifi_menu.main([]) == 0
        assert menu.fuzzel_calls == []
        assert menu.notifications == [("No Wi-Fi networks found", "normal")]
