from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from typing import cast

if TYPE_CHECKING:
    from ..models.user_minimal import UserMinimal
    from ..models.site import Site
    from ..models.bandwidth_class import BandwidthClass


T = TypeVar("T", bound="VLan")


@_attrs_define
class VLan:
    """
    Attributes:
        vlan_id (int | Unset):
        name (None | str | Unset):
        user (UserMinimal | Unset):
        site (Site | Unset):
        bandwidth_class (BandwidthClass | Unset):
    """

    vlan_id: int | Unset = UNSET
    name: None | str | Unset = UNSET
    user: UserMinimal | Unset = UNSET
    site: Site | Unset = UNSET
    bandwidth_class: BandwidthClass | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        vlan_id = self.vlan_id

        name: None | str | Unset
        if isinstance(self.name, Unset):
            name = UNSET
        else:
            name = self.name

        user: dict[str, Any] | Unset = UNSET
        if not isinstance(self.user, Unset):
            user = self.user.to_dict()

        site: dict[str, Any] | Unset = UNSET
        if not isinstance(self.site, Unset):
            site = self.site.to_dict()

        bandwidth_class: dict[str, Any] | Unset = UNSET
        if not isinstance(self.bandwidth_class, Unset):
            bandwidth_class = self.bandwidth_class.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if vlan_id is not UNSET:
            field_dict["vlanId"] = vlan_id
        if name is not UNSET:
            field_dict["name"] = name
        if user is not UNSET:
            field_dict["user"] = user
        if site is not UNSET:
            field_dict["site"] = site
        if bandwidth_class is not UNSET:
            field_dict["bandwidthClass"] = bandwidth_class

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.user_minimal import UserMinimal
        from ..models.site import Site
        from ..models.bandwidth_class import BandwidthClass

        d = dict(src_dict)
        vlan_id = d.pop("vlanId", UNSET)

        def _parse_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        name = _parse_name(d.pop("name", UNSET))

        _user = d.pop("user", UNSET)
        user: UserMinimal | Unset
        if isinstance(_user, Unset):
            user = UNSET
        else:
            user = UserMinimal.from_dict(_user)

        _site = d.pop("site", UNSET)
        site: Site | Unset
        if isinstance(_site, Unset):
            site = UNSET
        else:
            site = Site.from_dict(_site)

        _bandwidth_class = d.pop("bandwidthClass", UNSET)
        bandwidth_class: BandwidthClass | Unset
        if isinstance(_bandwidth_class, Unset):
            bandwidth_class = UNSET
        else:
            bandwidth_class = BandwidthClass.from_dict(_bandwidth_class)

        v_lan = cls(
            vlan_id=vlan_id,
            name=name,
            user=user,
            site=site,
            bandwidth_class=bandwidth_class,
        )

        v_lan.additional_properties = d
        return v_lan

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
