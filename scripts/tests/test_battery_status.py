"""Behavioural tests for the waybar battery module (scripts/battery_status.py)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import battery_status
import pytest
from battery_status import (
    Battery,
    ThresholdPolicy,
    combined_percent,
    held_by_threshold,
    read_batteries,
    render,
    tooltip,
)

# The two batteries of thiniel as /sys/class/power_supply reports them.
BAT0_FILES = {
    "manufacturer": "SONY\n",
    "model_name": "45N1111\n",
    "energy_now": "3370000\n",
    "energy_full": "15770000\n",
    "energy_full_design": "23200000\n",
    "status": "Charging\n",
    "cycle_count": "836\n",
    "technology": "Li-poly\n",
}
BAT1_FILES = {
    "manufacturer": "SANYO\n",
    "model_name": "45N1775\n",
    "energy_now": "810000\n",
    "energy_full": "17460000\n",
    "energy_full_design": "23200000\n",
    "status": "Not charging\n",
    "cycle_count": "456\n",
    "technology": "Li-ion\n",
}


def make_battery(
    name: str = "BAT0",
    now: int = 3_370_000,
    full: int = 15_770_000,
    design: int = 23_200_000,
    status: str = "Charging",
    model: str = "45N1111",
    manufacturer: str = "SONY",
    cycles: int | None = 836,
    technology: str | None = "Li-poly",
) -> Battery:
    return Battery(
        name=name,
        model=model,
        manufacturer=manufacturer,
        energy_now=now,
        energy_full=full,
        energy_full_design=design,
        status=status,
        cycle_count=cycles,
        technology=technology,
    )


class TestReadBatteries:
    def write(self, root: Path, name: str, files: dict[str, str]) -> None:
        directory = root / name
        directory.mkdir()
        for key, value in files.items():
            (directory / key).write_text(value)

    def test_reads_every_battery_sorted_by_name(self, tmp_path: Path) -> None:
        self.write(tmp_path, "BAT1", BAT1_FILES)
        self.write(tmp_path, "BAT0", BAT0_FILES)
        (tmp_path / "AC").mkdir()
        (tmp_path / "AC" / "online").write_text("1\n")

        batteries = read_batteries(tmp_path)

        assert [b.name for b in batteries] == ["BAT0", "BAT1"]
        assert [b.model for b in batteries] == ["45N1111", "45N1775"]
        assert [b.manufacturer for b in batteries] == ["SONY", "SANYO"]
        assert [b.status for b in batteries] == ["Charging", "Not charging"]
        assert [b.energy_now for b in batteries] == [3_370_000, 810_000]
        assert [b.energy_full_design for b in batteries] == [23_200_000, 23_200_000]
        assert [b.cycle_count for b in batteries] == [836, 456]

    def test_missing_optional_files_become_none(self, tmp_path: Path) -> None:
        self.write(tmp_path, "BAT0", {"energy_now": "1\n", "energy_full": "2\n"})

        battery = read_batteries(tmp_path)[0]

        assert battery.cycle_count is None
        assert battery.model is None
        assert battery.manufacturer is None
        assert battery.technology is None
        assert battery.energy_full_design is None

    def test_directory_without_energy_is_not_a_battery(self, tmp_path: Path) -> None:
        (tmp_path / "hidpp_battery_0").mkdir()
        (tmp_path / "hidpp_battery_0" / "capacity").write_text("55\n")

        assert read_batteries(tmp_path) == []

    def test_charging_status_variants_are_normalised(self, tmp_path: Path) -> None:
        self.write(tmp_path, "BAT0", dict(BAT0_FILES, status="Discharging\n"))
        self.write(tmp_path, "BAT1", dict(BAT1_FILES, status="Not charging\n"))

        assert [b.charging for b in read_batteries(tmp_path)] == [False, False]

    def test_charge_in_wh_is_used_from_current_and_voltage(
        self, tmp_path: Path
    ) -> None:
        self.write(
            tmp_path,
            "BAT0",
            {
                "charge_now": "2000000",
                "charge_full": "4000000",
                "voltage_min_design": "10000000",
            },
        )

        battery = read_batteries(tmp_path)[0]

        assert battery.energy_now == 20_000_000
        assert battery.energy_full == 40_000_000


class TestCombinedPercent:
    def test_weights_by_capacity(self) -> None:
        machine = [make_battery(), make_battery("BAT1", now=810_000, full=17_460_000)]

        assert combined_percent(machine) == 13

    def test_single_battery_is_its_own_percentage(self) -> None:
        assert combined_percent([make_battery(now=5_000_000, full=20_000_000)]) == 25

    def test_no_batteries_is_zero(self) -> None:
        assert combined_percent([]) == 0

    def test_clamps_to_one_hundred(self) -> None:
        assert combined_percent([make_battery(now=11, full=10, design=10)]) == 100


class TestChargingState:
    def test_charging_only_when_every_battery_charges(self) -> None:
        machine = [make_battery(), make_battery("BAT1", status="Charging")]
        assert battery_status.overall_charging(machine)

    def test_one_battery_not_charging_means_not_charging(self) -> None:
        machine = [make_battery(), make_battery("BAT1", status="Not charging")]
        assert not battery_status.overall_charging(machine)


class TestTooltip:
    def test_lists_each_battery_with_detail(self) -> None:
        text = tooltip(
            [
                make_battery(),
                make_battery(
                    "BAT1",
                    now=810_000,
                    full=17_460_000,
                    model="45N1775",
                    manufacturer="SANYO",
                    status="Not charging",
                    cycles=456,
                ),
            ]
        )

        assert "BAT0" in text
        assert "45N1111" in text
        assert "SONY" in text
        assert "21%" in text
        assert "3.37 Wh / 15.77 Wh" in text
        assert "578 cycles" not in text
        assert "836 cycles" in text
        assert "BAT1" in text
        assert "45N1775" in text
        assert "SANYO" in text
        assert "5%" in text
        assert "0.81 Wh / 17.46 Wh" in text
        assert "456 cycles" in text

    def test_reports_total_and_health(self) -> None:
        other = make_battery(
            "BAT1", now=810_000, full=17_460_000, status="Not charging"
        )

        text = tooltip([make_battery(), other])

        assert "Total" in text
        assert "4.18 Wh / 33.23 Wh" in text
        assert "13%" in text

    def test_skips_missing_fields(self) -> None:
        text = tooltip(
            [
                make_battery(
                    model=None,
                    manufacturer=None,
                    cycles=None,
                    status="Discharging",
                    design=None,
                )
            ]
        )

        assert "None" not in text
        assert "cycles" not in text
        assert "Discharging" in text

    def test_escapes_markup_characters(self) -> None:
        text = tooltip([make_battery(model="A&B<C>")])

        assert "BAT0 · SONY A&amp;B&lt;C&gt;</b>" in text
        assert "&amp;amp;" not in text

    def test_escapes_markup_in_status(self) -> None:
        text = tooltip([make_battery(status="Not charging <idle>")])

        assert "Not charging &lt;idle&gt;" in text
        assert "&amp;lt;" not in text

    def test_plain_output_carries_no_markup_entities(self) -> None:
        text = battery_status.format_plain([make_battery(model="A&B<C>")])

        assert "<b>" not in text
        assert "&amp;" not in text
        assert "&lt;" not in text
        assert "BAT0 · SONY A&B<C>" in text

    def test_explains_threshold_hold(self) -> None:
        machine = [
            make_battery(),
            make_battery(
                "BAT1", now=10_000_000, full=18_460_000, status="Not charging"
            ),
        ]
        policy = ThresholdPolicy(start=20, stop=80)

        text = tooltip(machine, policy)

        assert "20\u201380%" in text

    def test_makes_no_threshold_claim_without_policy(self) -> None:
        text = tooltip([make_battery()])

        assert "Threshold" not in text

    def test_no_batteries_says_so(self) -> None:
        assert tooltip([]) == "No battery detected"


class TestHeldByThreshold:
    def test_idle_while_another_charges_inside_the_band(self) -> None:
        policy = ThresholdPolicy(start=20, stop=80)
        machine = [make_battery(), make_battery("BAT1", status="Not charging")]

        assert held_by_threshold(machine, policy)

    def test_discharging_pack_is_not_blamed_on_the_band(self) -> None:
        policy = ThresholdPolicy(start=20, stop=80)
        machine = [make_battery(), make_battery("BAT1", status="Discharging")]

        assert not held_by_threshold(machine, policy)

    def test_not_held_outside_a_band(self) -> None:
        machine = [make_battery(), make_battery("BAT1", status="Not charging")]

        assert not held_by_threshold(machine, None)

    def test_not_held_when_nothing_charges(self) -> None:
        policy = ThresholdPolicy(start=20, stop=80)
        machine = [
            make_battery(status="Discharging"),
            make_battery("BAT1", status="Discharging"),
        ]

        assert not held_by_threshold(machine, policy)


class TestRender:
    def test_uses_percent_icon_and_state(self) -> None:
        machine = [
            make_battery(),
            make_battery("BAT1", now=810_000, full=17_460_000, status="Not charging"),
        ]

        payload = json.loads(render(machine, ThresholdPolicy(start=20, stop=80)))

        assert payload["text"] == "\U000f007a 13%"
        assert payload["percentage"] == 13
        assert payload["class"] == "battery critical"
        assert "BAT0" in payload["tooltip"]

    def test_charging_class_and_icon(self) -> None:
        machine = [make_battery(), make_battery("BAT1", status="Charging", now=400_000)]

        payload = json.loads(render(machine))

        assert payload["class"] == "battery charging"
        assert payload["text"] == "󰂄 12%"

    def test_critical_class(self) -> None:
        payload = json.loads(
            render([make_battery(now=1_000_000, full=20_000_000, status="Discharging")])
        )

        assert payload["class"] == "battery critical"

    def test_no_battery(self) -> None:
        payload = json.loads(render([]))

        assert payload["text"] == "no battery"
        assert "battery" in payload["class"]

    def test_plain_mode_prints_tooltip(self) -> None:
        text = battery_status.format_plain(
            [make_battery()], ThresholdPolicy(start=20, stop=80)
        )

        assert "BAT0" in text


@pytest.fixture
def cli(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> Any:
    """Run ``main`` against a stand-in power_supply tree."""

    class Cli:
        def __init__(self) -> None:
            self.root = tmp_path
            monkeypatch.setattr(battery_status, "DEFAULT_ROOT", tmp_path)
            monkeypatch.setattr(battery_status, "policy", lambda _path: None)

        def battery(self, name: str, files: dict[str, str]) -> None:
            directory = self.root / name
            directory.mkdir()
            for key, value in files.items():
                (directory / key).write_text(value)

        def run(self, *argv: str) -> tuple[int, str, str]:
            import contextlib
            import io

            out, err = io.StringIO(), io.StringIO()
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                code = battery_status.main(list(argv))
            return code, out.getvalue(), err.getvalue()

    return Cli()


class TestMain:
    def test_emits_waybar_json(self, cli: Any) -> None:
        cli.battery("BAT0", BAT0_FILES)
        cli.battery("BAT1", BAT1_FILES)

        code, out, _ = cli.run()

        assert code == 0
        payload = json.loads(out)
        assert payload["percentage"] == 13
        assert "BAT1" in payload["tooltip"]

    def test_plain_flag_prints_text(self, cli: Any) -> None:
        cli.battery("BAT0", BAT0_FILES)

        code, out, _ = cli.run("--plain")

        assert code == 0
        with pytest.raises(json.JSONDecodeError):
            json.loads(out)
        assert out.startswith("BAT0 · SONY 45N1111")

    def test_missing_tree_is_not_an_error(self, cli: Any) -> None:
        code, out, _ = cli.run()

        assert code == 0
        assert json.loads(out)["text"] == "no battery"
