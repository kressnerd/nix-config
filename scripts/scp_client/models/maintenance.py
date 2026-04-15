from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from dateutil.parser import isoparse
from typing import cast
import datetime


T = TypeVar("T", bound="Maintenance")


@_attrs_define
class Maintenance:
    """
    Attributes:
        start_at (datetime.datetime | None | Unset):  Example: 2022-03-10T16:15:50Z.
        finish_at (datetime.datetime | None | Unset):  Example: 2022-03-10T16:15:50Z.
    """

    start_at: datetime.datetime | None | Unset = UNSET
    finish_at: datetime.datetime | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        start_at: None | str | Unset
        if isinstance(self.start_at, Unset):
            start_at = UNSET
        elif isinstance(self.start_at, datetime.datetime):
            start_at = self.start_at.isoformat()
        else:
            start_at = self.start_at

        finish_at: None | str | Unset
        if isinstance(self.finish_at, Unset):
            finish_at = UNSET
        elif isinstance(self.finish_at, datetime.datetime):
            finish_at = self.finish_at.isoformat()
        else:
            finish_at = self.finish_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if start_at is not UNSET:
            field_dict["startAt"] = start_at
        if finish_at is not UNSET:
            field_dict["finishAt"] = finish_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_start_at(data: object) -> datetime.datetime | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                start_at_type_0 = isoparse(data)

                return start_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None | Unset, data)

        start_at = _parse_start_at(d.pop("startAt", UNSET))

        def _parse_finish_at(data: object) -> datetime.datetime | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                finish_at_type_0 = isoparse(data)

                return finish_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None | Unset, data)

        finish_at = _parse_finish_at(d.pop("finishAt", UNSET))

        maintenance = cls(
            start_at=start_at,
            finish_at=finish_at,
        )

        maintenance.additional_properties = d
        return maintenance

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
