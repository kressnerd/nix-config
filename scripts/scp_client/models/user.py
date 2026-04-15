from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="User")


@_attrs_define
class User:
    """
    Attributes:
        id (int | Unset):
        username (str | Unset):
        firstname (str | Unset):
        lastname (str | Unset):
        email (str | Unset):
        company (None | str | Unset):
        language (str | Unset):
        time_zone (None | str | Unset):
        show_nickname (bool | Unset):
        passwordless_mode (bool | Unset):
        secure_mode (bool | Unset):
        secure_mode_app_access (bool | Unset):
        api_ip_login_restrictions (None | str | Unset):
    """

    id: int | Unset = UNSET
    username: str | Unset = UNSET
    firstname: str | Unset = UNSET
    lastname: str | Unset = UNSET
    email: str | Unset = UNSET
    company: None | str | Unset = UNSET
    language: str | Unset = UNSET
    time_zone: None | str | Unset = UNSET
    show_nickname: bool | Unset = UNSET
    passwordless_mode: bool | Unset = UNSET
    secure_mode: bool | Unset = UNSET
    secure_mode_app_access: bool | Unset = UNSET
    api_ip_login_restrictions: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        username = self.username

        firstname = self.firstname

        lastname = self.lastname

        email = self.email

        company: None | str | Unset
        if isinstance(self.company, Unset):
            company = UNSET
        else:
            company = self.company

        language = self.language

        time_zone: None | str | Unset
        if isinstance(self.time_zone, Unset):
            time_zone = UNSET
        else:
            time_zone = self.time_zone

        show_nickname = self.show_nickname

        passwordless_mode = self.passwordless_mode

        secure_mode = self.secure_mode

        secure_mode_app_access = self.secure_mode_app_access

        api_ip_login_restrictions: None | str | Unset
        if isinstance(self.api_ip_login_restrictions, Unset):
            api_ip_login_restrictions = UNSET
        else:
            api_ip_login_restrictions = self.api_ip_login_restrictions

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if username is not UNSET:
            field_dict["username"] = username
        if firstname is not UNSET:
            field_dict["firstname"] = firstname
        if lastname is not UNSET:
            field_dict["lastname"] = lastname
        if email is not UNSET:
            field_dict["email"] = email
        if company is not UNSET:
            field_dict["company"] = company
        if language is not UNSET:
            field_dict["language"] = language
        if time_zone is not UNSET:
            field_dict["timeZone"] = time_zone
        if show_nickname is not UNSET:
            field_dict["showNickname"] = show_nickname
        if passwordless_mode is not UNSET:
            field_dict["passwordlessMode"] = passwordless_mode
        if secure_mode is not UNSET:
            field_dict["secureMode"] = secure_mode
        if secure_mode_app_access is not UNSET:
            field_dict["secureModeAppAccess"] = secure_mode_app_access
        if api_ip_login_restrictions is not UNSET:
            field_dict["apiIpLoginRestrictions"] = api_ip_login_restrictions

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id", UNSET)

        username = d.pop("username", UNSET)

        firstname = d.pop("firstname", UNSET)

        lastname = d.pop("lastname", UNSET)

        email = d.pop("email", UNSET)

        def _parse_company(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        company = _parse_company(d.pop("company", UNSET))

        language = d.pop("language", UNSET)

        def _parse_time_zone(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        time_zone = _parse_time_zone(d.pop("timeZone", UNSET))

        show_nickname = d.pop("showNickname", UNSET)

        passwordless_mode = d.pop("passwordlessMode", UNSET)

        secure_mode = d.pop("secureMode", UNSET)

        secure_mode_app_access = d.pop("secureModeAppAccess", UNSET)

        def _parse_api_ip_login_restrictions(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        api_ip_login_restrictions = _parse_api_ip_login_restrictions(
            d.pop("apiIpLoginRestrictions", UNSET)
        )

        user = cls(
            id=id,
            username=username,
            firstname=firstname,
            lastname=lastname,
            email=email,
            company=company,
            language=language,
            time_zone=time_zone,
            show_nickname=show_nickname,
            passwordless_mode=passwordless_mode,
            secure_mode=secure_mode,
            secure_mode_app_access=secure_mode_app_access,
            api_ip_login_restrictions=api_ip_login_restrictions,
        )

        user.additional_properties = d
        return user

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
