from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="S3CompletedPart")


@_attrs_define
class S3CompletedPart:
    """
    Attributes:
        e_tag (str | Unset):
        part_number (int | Unset):
    """

    e_tag: str | Unset = UNSET
    part_number: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        e_tag = self.e_tag

        part_number = self.part_number

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if e_tag is not UNSET:
            field_dict["ETag"] = e_tag
        if part_number is not UNSET:
            field_dict["partNumber"] = part_number

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        e_tag = d.pop("ETag", UNSET)

        part_number = d.pop("partNumber", UNSET)

        s3_completed_part = cls(
            e_tag=e_tag,
            part_number=part_number,
        )

        s3_completed_part.additional_properties = d
        return s3_completed_part

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
