from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from dateutil.parser import isoparse
import datetime


T = TypeVar("T", bound="S3Object")


@_attrs_define
class S3Object:
    """
    Attributes:
        key (str | Unset):
        last_modified (datetime.datetime | Unset):  Example: 2022-03-10T16:15:50Z.
        size_in_b (int | Unset):
    """

    key: str | Unset = UNSET
    last_modified: datetime.datetime | Unset = UNSET
    size_in_b: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        last_modified: str | Unset = UNSET
        if not isinstance(self.last_modified, Unset):
            last_modified = self.last_modified.isoformat()

        size_in_b = self.size_in_b

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if key is not UNSET:
            field_dict["key"] = key
        if last_modified is not UNSET:
            field_dict["lastModified"] = last_modified
        if size_in_b is not UNSET:
            field_dict["sizeInB"] = size_in_b

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key", UNSET)

        _last_modified = d.pop("lastModified", UNSET)
        last_modified: datetime.datetime | Unset
        if isinstance(_last_modified, Unset):
            last_modified = UNSET
        else:
            last_modified = isoparse(_last_modified)

        size_in_b = d.pop("sizeInB", UNSET)

        s3_object = cls(
            key=key,
            last_modified=last_modified,
            size_in_b=size_in_b,
        )

        s3_object.additional_properties = d
        return s3_object

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
