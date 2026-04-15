from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from dateutil.parser import isoparse
import datetime


T = TypeVar("T", bound="TaskProgress")


@_attrs_define
class TaskProgress:
    """
    Attributes:
        expected_finished_at (datetime.datetime | Unset):  Example: 2022-03-10T16:15:50Z.
        progress_in_percent (float | Unset):
    """

    expected_finished_at: datetime.datetime | Unset = UNSET
    progress_in_percent: float | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        expected_finished_at: str | Unset = UNSET
        if not isinstance(self.expected_finished_at, Unset):
            expected_finished_at = self.expected_finished_at.isoformat()

        progress_in_percent = self.progress_in_percent

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if expected_finished_at is not UNSET:
            field_dict["expectedFinishedAt"] = expected_finished_at
        if progress_in_percent is not UNSET:
            field_dict["progressInPercent"] = progress_in_percent

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _expected_finished_at = d.pop("expectedFinishedAt", UNSET)
        expected_finished_at: datetime.datetime | Unset
        if isinstance(_expected_finished_at, Unset):
            expected_finished_at = UNSET
        else:
            expected_finished_at = isoparse(_expected_finished_at)

        progress_in_percent = d.pop("progressInPercent", UNSET)

        task_progress = cls(
            expected_finished_at=expected_finished_at,
            progress_in_percent=progress_in_percent,
        )

        task_progress.additional_properties = d
        return task_progress

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
