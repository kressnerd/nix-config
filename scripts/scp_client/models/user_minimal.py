from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast


T = TypeVar("T", bound="UserMinimal")


@_attrs_define
class UserMinimal:
    """
    Attributes:
        id (int | Unset):
        username (str | Unset):
        firstname (str | Unset):
        lastname (str | Unset):
        email (str | Unset):
        company (None | str | Unset):
    """

    id: int | Unset = UNSET
    username: str | Unset = UNSET
    firstname: str | Unset = UNSET
    lastname: str | Unset = UNSET
    email: str | Unset = UNSET
    company: None | str | Unset = UNSET
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

        user_minimal = cls(
            id=id,
            username=username,
            firstname=firstname,
            lastname=lastname,
            email=email,
            company=company,
        )

        user_minimal.additional_properties = d
        return user_minimal

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
