from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="ServerImageSetup")


@_attrs_define
class ServerImageSetup:
    """
    Attributes:
        image_flavour_id (int | Unset):
        disk_name (str | Unset):
        root_partition_full_disk_size (bool | Unset):
        hostname (None | str | Unset):
        locale (None | str | Unset):
        timezone (None | str | Unset):
        additional_user_username (None | str | Unset):
        additional_user_password (None | str | Unset):
        ssh_key_ids (list[int] | None | Unset):
        ssh_password_authentication (bool | None | Unset):
        custom_script (None | str | Unset):
        email_to_executing_user (bool | None | Unset):
    """

    image_flavour_id: int | Unset = UNSET
    disk_name: str | Unset = UNSET
    root_partition_full_disk_size: bool | Unset = UNSET
    hostname: None | str | Unset = UNSET
    locale: None | str | Unset = UNSET
    timezone: None | str | Unset = UNSET
    additional_user_username: None | str | Unset = UNSET
    additional_user_password: None | str | Unset = UNSET
    ssh_key_ids: list[int] | None | Unset = UNSET
    ssh_password_authentication: bool | None | Unset = UNSET
    custom_script: None | str | Unset = UNSET
    email_to_executing_user: bool | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        image_flavour_id = self.image_flavour_id

        disk_name = self.disk_name

        root_partition_full_disk_size = self.root_partition_full_disk_size

        hostname: None | str | Unset
        if isinstance(self.hostname, Unset):
            hostname = UNSET
        else:
            hostname = self.hostname

        locale: None | str | Unset
        if isinstance(self.locale, Unset):
            locale = UNSET
        else:
            locale = self.locale

        timezone: None | str | Unset
        if isinstance(self.timezone, Unset):
            timezone = UNSET
        else:
            timezone = self.timezone

        additional_user_username: None | str | Unset
        if isinstance(self.additional_user_username, Unset):
            additional_user_username = UNSET
        else:
            additional_user_username = self.additional_user_username

        additional_user_password: None | str | Unset
        if isinstance(self.additional_user_password, Unset):
            additional_user_password = UNSET
        else:
            additional_user_password = self.additional_user_password

        ssh_key_ids: list[int] | None | Unset
        if isinstance(self.ssh_key_ids, Unset):
            ssh_key_ids = UNSET
        elif isinstance(self.ssh_key_ids, list):
            ssh_key_ids = self.ssh_key_ids

        else:
            ssh_key_ids = self.ssh_key_ids

        ssh_password_authentication: bool | None | Unset
        if isinstance(self.ssh_password_authentication, Unset):
            ssh_password_authentication = UNSET
        else:
            ssh_password_authentication = self.ssh_password_authentication

        custom_script: None | str | Unset
        if isinstance(self.custom_script, Unset):
            custom_script = UNSET
        else:
            custom_script = self.custom_script

        email_to_executing_user: bool | None | Unset
        if isinstance(self.email_to_executing_user, Unset):
            email_to_executing_user = UNSET
        else:
            email_to_executing_user = self.email_to_executing_user

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if image_flavour_id is not UNSET:
            field_dict["imageFlavourId"] = image_flavour_id
        if disk_name is not UNSET:
            field_dict["diskName"] = disk_name
        if root_partition_full_disk_size is not UNSET:
            field_dict["rootPartitionFullDiskSize"] = root_partition_full_disk_size
        if hostname is not UNSET:
            field_dict["hostname"] = hostname
        if locale is not UNSET:
            field_dict["locale"] = locale
        if timezone is not UNSET:
            field_dict["timezone"] = timezone
        if additional_user_username is not UNSET:
            field_dict["additionalUserUsername"] = additional_user_username
        if additional_user_password is not UNSET:
            field_dict["additionalUserPassword"] = additional_user_password
        if ssh_key_ids is not UNSET:
            field_dict["sshKeyIds"] = ssh_key_ids
        if ssh_password_authentication is not UNSET:
            field_dict["sshPasswordAuthentication"] = ssh_password_authentication
        if custom_script is not UNSET:
            field_dict["customScript"] = custom_script
        if email_to_executing_user is not UNSET:
            field_dict["emailToExecutingUser"] = email_to_executing_user

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        image_flavour_id = d.pop("imageFlavourId", UNSET)

        disk_name = d.pop("diskName", UNSET)

        root_partition_full_disk_size = d.pop("rootPartitionFullDiskSize", UNSET)

        def _parse_hostname(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        hostname = _parse_hostname(d.pop("hostname", UNSET))

        def _parse_locale(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        locale = _parse_locale(d.pop("locale", UNSET))

        def _parse_timezone(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        timezone = _parse_timezone(d.pop("timezone", UNSET))

        def _parse_additional_user_username(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        additional_user_username = _parse_additional_user_username(
            d.pop("additionalUserUsername", UNSET)
        )

        def _parse_additional_user_password(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        additional_user_password = _parse_additional_user_password(
            d.pop("additionalUserPassword", UNSET)
        )

        def _parse_ssh_key_ids(data: object) -> list[int] | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                ssh_key_ids_type_0 = cast(list[int], data)

                return ssh_key_ids_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[int] | None | Unset, data)

        ssh_key_ids = _parse_ssh_key_ids(d.pop("sshKeyIds", UNSET))

        def _parse_ssh_password_authentication(data: object) -> bool | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(bool | None | Unset, data)

        ssh_password_authentication = _parse_ssh_password_authentication(
            d.pop("sshPasswordAuthentication", UNSET)
        )

        def _parse_custom_script(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        custom_script = _parse_custom_script(d.pop("customScript", UNSET))

        def _parse_email_to_executing_user(data: object) -> bool | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(bool | None | Unset, data)

        email_to_executing_user = _parse_email_to_executing_user(
            d.pop("emailToExecutingUser", UNSET)
        )

        server_image_setup = cls(
            image_flavour_id=image_flavour_id,
            disk_name=disk_name,
            root_partition_full_disk_size=root_partition_full_disk_size,
            hostname=hostname,
            locale=locale,
            timezone=timezone,
            additional_user_username=additional_user_username,
            additional_user_password=additional_user_password,
            ssh_key_ids=ssh_key_ids,
            ssh_password_authentication=ssh_password_authentication,
            custom_script=custom_script,
            email_to_executing_user=email_to_executing_user,
        )

        server_image_setup.additional_properties = d
        return server_image_setup

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
