from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="UserSave")


@_attrs_define
class UserSave:
    """
    Attributes:
        language (str):
        time_zone (str):
        id (int | Unset):
        api_ip_login_restrictions (str | Unset):
        password (None | str | Unset):
        old_password (None | str | Unset):
        soap_webservice_password (None | str | Unset):
        show_nickname (bool | Unset):
        passwordless_mode (bool | Unset):
        secure_mode (bool | Unset):
        secure_mode_app_access (bool | Unset):
    """

    language: str
    time_zone: str
    id: int | Unset = UNSET
    api_ip_login_restrictions: str | Unset = UNSET
    password: None | str | Unset = UNSET
    old_password: None | str | Unset = UNSET
    soap_webservice_password: None | str | Unset = UNSET
    show_nickname: bool | Unset = UNSET
    passwordless_mode: bool | Unset = UNSET
    secure_mode: bool | Unset = UNSET
    secure_mode_app_access: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        language = self.language

        time_zone = self.time_zone

        id = self.id

        api_ip_login_restrictions = self.api_ip_login_restrictions

        password: None | str | Unset
        if isinstance(self.password, Unset):
            password = UNSET
        else:
            password = self.password

        old_password: None | str | Unset
        if isinstance(self.old_password, Unset):
            old_password = UNSET
        else:
            old_password = self.old_password

        soap_webservice_password: None | str | Unset
        if isinstance(self.soap_webservice_password, Unset):
            soap_webservice_password = UNSET
        else:
            soap_webservice_password = self.soap_webservice_password

        show_nickname = self.show_nickname

        passwordless_mode = self.passwordless_mode

        secure_mode = self.secure_mode

        secure_mode_app_access = self.secure_mode_app_access

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "language": language,
                "timeZone": time_zone,
            }
        )
        if id is not UNSET:
            field_dict["id"] = id
        if api_ip_login_restrictions is not UNSET:
            field_dict["apiIpLoginRestrictions"] = api_ip_login_restrictions
        if password is not UNSET:
            field_dict["password"] = password
        if old_password is not UNSET:
            field_dict["oldPassword"] = old_password
        if soap_webservice_password is not UNSET:
            field_dict["soapWebservicePassword"] = soap_webservice_password
        if show_nickname is not UNSET:
            field_dict["showNickname"] = show_nickname
        if passwordless_mode is not UNSET:
            field_dict["passwordlessMode"] = passwordless_mode
        if secure_mode is not UNSET:
            field_dict["secureMode"] = secure_mode
        if secure_mode_app_access is not UNSET:
            field_dict["secureModeAppAccess"] = secure_mode_app_access

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        language = d.pop("language")

        time_zone = d.pop("timeZone")

        id = d.pop("id", UNSET)

        api_ip_login_restrictions = d.pop("apiIpLoginRestrictions", UNSET)

        def _parse_password(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        password = _parse_password(d.pop("password", UNSET))

        def _parse_old_password(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        old_password = _parse_old_password(d.pop("oldPassword", UNSET))

        def _parse_soap_webservice_password(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        soap_webservice_password = _parse_soap_webservice_password(
            d.pop("soapWebservicePassword", UNSET)
        )

        show_nickname = d.pop("showNickname", UNSET)

        passwordless_mode = d.pop("passwordlessMode", UNSET)

        secure_mode = d.pop("secureMode", UNSET)

        secure_mode_app_access = d.pop("secureModeAppAccess", UNSET)

        user_save = cls(
            language=language,
            time_zone=time_zone,
            id=id,
            api_ip_login_restrictions=api_ip_login_restrictions,
            password=password,
            old_password=old_password,
            soap_webservice_password=soap_webservice_password,
            show_nickname=show_nickname,
            passwordless_mode=passwordless_mode,
            secure_mode=secure_mode,
            secure_mode_app_access=secure_mode_app_access,
        )

        user_save.additional_properties = d
        return user_save

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
