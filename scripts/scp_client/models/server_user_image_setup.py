from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="ServerUserImageSetup")


@_attrs_define
class ServerUserImageSetup:
    """
    Attributes:
        user_image_name (str):
        disk_name (None | str | Unset):
        email_notification (bool | None | Unset):
    """

    user_image_name: str
    disk_name: None | str | Unset = UNSET
    email_notification: bool | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_image_name = self.user_image_name

        disk_name: None | str | Unset
        if isinstance(self.disk_name, Unset):
            disk_name = UNSET
        else:
            disk_name = self.disk_name

        email_notification: bool | None | Unset
        if isinstance(self.email_notification, Unset):
            email_notification = UNSET
        else:
            email_notification = self.email_notification

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "userImageName": user_image_name,
            }
        )
        if disk_name is not UNSET:
            field_dict["diskName"] = disk_name
        if email_notification is not UNSET:
            field_dict["emailNotification"] = email_notification

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        user_image_name = d.pop("userImageName")

        def _parse_disk_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        disk_name = _parse_disk_name(d.pop("diskName", UNSET))

        def _parse_email_notification(data: object) -> bool | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(bool | None | Unset, data)

        email_notification = _parse_email_notification(
            d.pop("emailNotification", UNSET)
        )

        server_user_image_setup = cls(
            user_image_name=user_image_name,
            disk_name=disk_name,
            email_notification=email_notification,
        )

        server_user_image_setup.additional_properties = d
        return server_user_image_setup

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
