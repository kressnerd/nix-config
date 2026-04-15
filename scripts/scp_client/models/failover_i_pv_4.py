from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.user_minimal import UserMinimal
    from ..models.site import Site
    from ..models.server_minimal import ServerMinimal


T = TypeVar("T", bound="FailoverIPv4")


@_attrs_define
class FailoverIPv4:
    """
    Attributes:
        id (int | Unset):
        ip (str | Unset):
        cidr_suffix (int | Unset):
        user (UserMinimal | Unset):
        editable (bool | Unset):
        site (Site | Unset):
        server (ServerMinimal | Unset):
    """

    id: int | Unset = UNSET
    ip: str | Unset = UNSET
    cidr_suffix: int | Unset = UNSET
    user: UserMinimal | Unset = UNSET
    editable: bool | Unset = UNSET
    site: Site | Unset = UNSET
    server: ServerMinimal | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ip = self.ip

        cidr_suffix = self.cidr_suffix

        user: dict[str, Any] | Unset = UNSET
        if not isinstance(self.user, Unset):
            user = self.user.to_dict()

        editable = self.editable

        site: dict[str, Any] | Unset = UNSET
        if not isinstance(self.site, Unset):
            site = self.site.to_dict()

        server: dict[str, Any] | Unset = UNSET
        if not isinstance(self.server, Unset):
            server = self.server.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if ip is not UNSET:
            field_dict["ip"] = ip
        if cidr_suffix is not UNSET:
            field_dict["cidrSuffix"] = cidr_suffix
        if user is not UNSET:
            field_dict["user"] = user
        if editable is not UNSET:
            field_dict["editable"] = editable
        if site is not UNSET:
            field_dict["site"] = site
        if server is not UNSET:
            field_dict["server"] = server

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.user_minimal import UserMinimal
        from ..models.site import Site
        from ..models.server_minimal import ServerMinimal

        d = dict(src_dict)
        id = d.pop("id", UNSET)

        ip = d.pop("ip", UNSET)

        cidr_suffix = d.pop("cidrSuffix", UNSET)

        _user = d.pop("user", UNSET)
        user: UserMinimal | Unset
        if isinstance(_user, Unset):
            user = UNSET
        else:
            user = UserMinimal.from_dict(_user)

        editable = d.pop("editable", UNSET)

        _site = d.pop("site", UNSET)
        site: Site | Unset
        if isinstance(_site, Unset):
            site = UNSET
        else:
            site = Site.from_dict(_site)

        _server = d.pop("server", UNSET)
        server: ServerMinimal | Unset
        if isinstance(_server, Unset):
            server = UNSET
        else:
            server = ServerMinimal.from_dict(_server)

        failover_i_pv_4 = cls(
            id=id,
            ip=ip,
            cidr_suffix=cidr_suffix,
            user=user,
            editable=editable,
            site=site,
            server=server,
        )

        failover_i_pv_4.additional_properties = d
        return failover_i_pv_4

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
