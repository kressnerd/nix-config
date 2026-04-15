from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast

if TYPE_CHECKING:
    from ..models.server_template_minimal import ServerTemplateMinimal


T = TypeVar("T", bound="ServerListMinimal")


@_attrs_define
class ServerListMinimal:
    """
    Attributes:
        id (int | Unset):
        name (str | Unset):
        hostname (None | str | Unset):
        nickname (None | str | Unset):
        disabled (bool | Unset):
        template (ServerTemplateMinimal | Unset):
    """

    id: int | Unset = UNSET
    name: str | Unset = UNSET
    hostname: None | str | Unset = UNSET
    nickname: None | str | Unset = UNSET
    disabled: bool | Unset = UNSET
    template: ServerTemplateMinimal | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        hostname: None | str | Unset
        if isinstance(self.hostname, Unset):
            hostname = UNSET
        else:
            hostname = self.hostname

        nickname: None | str | Unset
        if isinstance(self.nickname, Unset):
            nickname = UNSET
        else:
            nickname = self.nickname

        disabled = self.disabled

        template: dict[str, Any] | Unset = UNSET
        if not isinstance(self.template, Unset):
            template = self.template.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if name is not UNSET:
            field_dict["name"] = name
        if hostname is not UNSET:
            field_dict["hostname"] = hostname
        if nickname is not UNSET:
            field_dict["nickname"] = nickname
        if disabled is not UNSET:
            field_dict["disabled"] = disabled
        if template is not UNSET:
            field_dict["template"] = template

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.server_template_minimal import ServerTemplateMinimal

        d = dict(src_dict)
        id = d.pop("id", UNSET)

        name = d.pop("name", UNSET)

        def _parse_hostname(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        hostname = _parse_hostname(d.pop("hostname", UNSET))

        def _parse_nickname(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        nickname = _parse_nickname(d.pop("nickname", UNSET))

        disabled = d.pop("disabled", UNSET)

        _template = d.pop("template", UNSET)
        template: ServerTemplateMinimal | Unset
        if isinstance(_template, Unset):
            template = UNSET
        else:
            template = ServerTemplateMinimal.from_dict(_template)

        server_list_minimal = cls(
            id=id,
            name=name,
            hostname=hostname,
            nickname=nickname,
            disabled=disabled,
            template=template,
        )

        server_list_minimal.additional_properties = d
        return server_list_minimal

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
