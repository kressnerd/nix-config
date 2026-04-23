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


T = TypeVar("T", bound="FailoverIPv6")


@_attrs_define
class FailoverIPv6:
    """
    Attributes:
        id (int | Unset):
        network_prefix (str | Unset):
        network_prefix_length (int | Unset):
        user (UserMinimal | Unset):
        editable (bool | Unset):
        site (Site | Unset):
        server (ServerMinimal | Unset):
    """

    id: int | Unset = UNSET
    network_prefix: str | Unset = UNSET
    network_prefix_length: int | Unset = UNSET
    user: UserMinimal | Unset = UNSET
    editable: bool | Unset = UNSET
    site: Site | Unset = UNSET
    server: ServerMinimal | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        network_prefix = self.network_prefix

        network_prefix_length = self.network_prefix_length

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
        if network_prefix is not UNSET:
            field_dict["networkPrefix"] = network_prefix
        if network_prefix_length is not UNSET:
            field_dict["networkPrefixLength"] = network_prefix_length
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

        network_prefix = d.pop("networkPrefix", UNSET)

        network_prefix_length = d.pop("networkPrefixLength", UNSET)

        _user = d.pop("user", UNSET)
        user: UserMinimal | Unset
        if isinstance(_user, Unset) or _user is None:
            user = _user  # type: ignore[assignment]
        else:
            user = UserMinimal.from_dict(_user)

        editable = d.pop("editable", UNSET)

        _site = d.pop("site", UNSET)
        site: Site | Unset
        if isinstance(_site, Unset) or _site is None:
            site = _site  # type: ignore[assignment]
        else:
            site = Site.from_dict(_site)

        _server = d.pop("server", UNSET)
        server: ServerMinimal | Unset
        if isinstance(_server, Unset) or _server is None:
            server = _server  # type: ignore[assignment]
        else:
            server = ServerMinimal.from_dict(_server)

        failover_i_pv_6 = cls(
            id=id,
            network_prefix=network_prefix,
            network_prefix_length=network_prefix_length,
            user=user,
            editable=editable,
            site=site,
            server=server,
        )

        failover_i_pv_6.additional_properties = d
        return failover_i_pv_6

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
