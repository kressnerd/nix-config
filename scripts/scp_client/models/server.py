from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.architecture import Architecture
from typing import cast

if TYPE_CHECKING:
    from ..models.i_pv_6_address_minimal import IPv6AddressMinimal
    from ..models.server_info import ServerInfo
    from ..models.site import Site
    from ..models.i_pv_4_address_minimal import IPv4AddressMinimal
    from ..models.server_template_minimal import ServerTemplateMinimal


T = TypeVar("T", bound="Server")


@_attrs_define
class Server:
    """
    Attributes:
        id (int | Unset):
        name (str | Unset):
        hostname (None | str | Unset):
        nickname (None | str | Unset):
        disabled (bool | Unset):
        template (ServerTemplateMinimal | Unset):
        server_live_info (ServerInfo | Unset):
        ipv_4_addresses (list[IPv4AddressMinimal] | Unset):
        ipv_6_addresses (list[IPv6AddressMinimal] | Unset):
        site (Site | Unset):
        snapshot_count (int | Unset):
        max_cpu_count (int | Unset):
        disks_available_space_in_mi_b (int | Unset):
        rescue_system_active (bool | Unset):
        snapshot_allowed (bool | Unset):
        architecture (Architecture | Unset):
        gpu_driver_available (bool | Unset):
    """

    id: int | Unset = UNSET
    name: str | Unset = UNSET
    hostname: None | str | Unset = UNSET
    nickname: None | str | Unset = UNSET
    disabled: bool | Unset = UNSET
    template: ServerTemplateMinimal | Unset = UNSET
    server_live_info: ServerInfo | Unset = UNSET
    ipv_4_addresses: list[IPv4AddressMinimal] | Unset = UNSET
    ipv_6_addresses: list[IPv6AddressMinimal] | Unset = UNSET
    site: Site | Unset = UNSET
    snapshot_count: int | Unset = UNSET
    max_cpu_count: int | Unset = UNSET
    disks_available_space_in_mi_b: int | Unset = UNSET
    rescue_system_active: bool | Unset = UNSET
    snapshot_allowed: bool | Unset = UNSET
    architecture: Architecture | Unset = UNSET
    gpu_driver_available: bool | Unset = UNSET
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

        server_live_info: dict[str, Any] | Unset = UNSET
        if not isinstance(self.server_live_info, Unset):
            server_live_info = self.server_live_info.to_dict()

        ipv_4_addresses: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.ipv_4_addresses, Unset):
            ipv_4_addresses = []
            for ipv_4_addresses_item_data in self.ipv_4_addresses:
                ipv_4_addresses_item = ipv_4_addresses_item_data.to_dict()
                ipv_4_addresses.append(ipv_4_addresses_item)

        ipv_6_addresses: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.ipv_6_addresses, Unset):
            ipv_6_addresses = []
            for ipv_6_addresses_item_data in self.ipv_6_addresses:
                ipv_6_addresses_item = ipv_6_addresses_item_data.to_dict()
                ipv_6_addresses.append(ipv_6_addresses_item)

        site: dict[str, Any] | Unset = UNSET
        if not isinstance(self.site, Unset):
            site = self.site.to_dict()

        snapshot_count = self.snapshot_count

        max_cpu_count = self.max_cpu_count

        disks_available_space_in_mi_b = self.disks_available_space_in_mi_b

        rescue_system_active = self.rescue_system_active

        snapshot_allowed = self.snapshot_allowed

        architecture: str | Unset = UNSET
        if not isinstance(self.architecture, Unset):
            architecture = self.architecture.value

        gpu_driver_available = self.gpu_driver_available

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
        if server_live_info is not UNSET:
            field_dict["serverLiveInfo"] = server_live_info
        if ipv_4_addresses is not UNSET:
            field_dict["ipv4Addresses"] = ipv_4_addresses
        if ipv_6_addresses is not UNSET:
            field_dict["ipv6Addresses"] = ipv_6_addresses
        if site is not UNSET:
            field_dict["site"] = site
        if snapshot_count is not UNSET:
            field_dict["snapshotCount"] = snapshot_count
        if max_cpu_count is not UNSET:
            field_dict["maxCpuCount"] = max_cpu_count
        if disks_available_space_in_mi_b is not UNSET:
            field_dict["disksAvailableSpaceInMiB"] = disks_available_space_in_mi_b
        if rescue_system_active is not UNSET:
            field_dict["rescueSystemActive"] = rescue_system_active
        if snapshot_allowed is not UNSET:
            field_dict["snapshotAllowed"] = snapshot_allowed
        if architecture is not UNSET:
            field_dict["architecture"] = architecture
        if gpu_driver_available is not UNSET:
            field_dict["gpuDriverAvailable"] = gpu_driver_available

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.i_pv_6_address_minimal import IPv6AddressMinimal
        from ..models.server_info import ServerInfo
        from ..models.site import Site
        from ..models.i_pv_4_address_minimal import IPv4AddressMinimal
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

        _server_live_info = d.pop("serverLiveInfo", UNSET)
        server_live_info: ServerInfo | Unset
        if isinstance(_server_live_info, Unset):
            server_live_info = UNSET
        else:
            server_live_info = ServerInfo.from_dict(_server_live_info)

        _ipv_4_addresses = d.pop("ipv4Addresses", UNSET)
        ipv_4_addresses: list[IPv4AddressMinimal] | Unset = UNSET
        if _ipv_4_addresses is not UNSET:
            ipv_4_addresses = []
            for ipv_4_addresses_item_data in _ipv_4_addresses:
                ipv_4_addresses_item = IPv4AddressMinimal.from_dict(
                    ipv_4_addresses_item_data
                )

                ipv_4_addresses.append(ipv_4_addresses_item)

        _ipv_6_addresses = d.pop("ipv6Addresses", UNSET)
        ipv_6_addresses: list[IPv6AddressMinimal] | Unset = UNSET
        if _ipv_6_addresses is not UNSET:
            ipv_6_addresses = []
            for ipv_6_addresses_item_data in _ipv_6_addresses:
                ipv_6_addresses_item = IPv6AddressMinimal.from_dict(
                    ipv_6_addresses_item_data
                )

                ipv_6_addresses.append(ipv_6_addresses_item)

        _site = d.pop("site", UNSET)
        site: Site | Unset
        if isinstance(_site, Unset):
            site = UNSET
        else:
            site = Site.from_dict(_site)

        snapshot_count = d.pop("snapshotCount", UNSET)

        max_cpu_count = d.pop("maxCpuCount", UNSET)

        disks_available_space_in_mi_b = d.pop("disksAvailableSpaceInMiB", UNSET)

        rescue_system_active = d.pop("rescueSystemActive", UNSET)

        snapshot_allowed = d.pop("snapshotAllowed", UNSET)

        _architecture = d.pop("architecture", UNSET)
        architecture: Architecture | Unset
        if isinstance(_architecture, Unset):
            architecture = UNSET
        else:
            architecture = Architecture(_architecture)

        gpu_driver_available = d.pop("gpuDriverAvailable", UNSET)

        server = cls(
            id=id,
            name=name,
            hostname=hostname,
            nickname=nickname,
            disabled=disabled,
            template=template,
            server_live_info=server_live_info,
            ipv_4_addresses=ipv_4_addresses,
            ipv_6_addresses=ipv_6_addresses,
            site=site,
            snapshot_count=snapshot_count,
            max_cpu_count=max_cpu_count,
            disks_available_space_in_mi_b=disks_available_space_in_mi_b,
            rescue_system_active=rescue_system_active,
            snapshot_allowed=snapshot_allowed,
            architecture=architecture,
            gpu_driver_available=gpu_driver_available,
        )

        server.additional_properties = d
        return server

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
