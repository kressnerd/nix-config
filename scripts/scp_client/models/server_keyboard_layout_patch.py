from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="ServerKeyboardLayoutPatch")


@_attrs_define
class ServerKeyboardLayoutPatch:
    """
    Attributes:
        keyboard_layout (str | Unset):
    """

    keyboard_layout: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        keyboard_layout = self.keyboard_layout

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if keyboard_layout is not UNSET:
            field_dict["keyboardLayout"] = keyboard_layout

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        keyboard_layout = d.pop("keyboardLayout", UNSET)

        server_keyboard_layout_patch = cls(
            keyboard_layout=keyboard_layout,
        )

        server_keyboard_layout_patch.additional_properties = d
        return server_keyboard_layout_patch

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
