from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.firewall_action import FirewallAction
from ..models.firewall_protocol import FirewallProtocol
from ..models.firewall_rule_direction import FirewallRuleDirection
from typing import cast


T = TypeVar("T", bound="FirewallRule")


@_attrs_define
class FirewallRule:
    """
    Attributes:
        direction (FirewallRuleDirection):
        protocol (FirewallProtocol):
        action (FirewallAction):
        number_of_effective_rules (int | Unset):
        description (None | str | Unset):
        sources (list[str] | Unset): Valid configurations are any IP (null or empty array), IPv4/IPv6 address (f.e.
            192.168.10.1 or 0092:e10f:cb66:35a9::) or IPv4 network / IPv6 prefix (f.e. 192.168.10.0/24 or
            0092:e10f:cb66:35a9::/64). If more than one IP/network is specified for the source, the destination must be
            empty (any) or contain only a single IP/network. If IPv4 addresses and IPv6 addresses are mixed in sources,
            destinations must empty (any).
        source_ports (str | Unset): Valid configurations are any port (null), single port (f.e. 1234) or port range
            (f.e. 1024-65535).
        destinations (list[str] | Unset): Valid configurations are any IP (null or empty array), IPv4/IPv6 address (f.e.
            192.168.10.1 or 0092:e10f:cb66:35a9::) or IPv4 network / IPv6 prefix (f.e. 192.168.10.0/24 or
            0092:e10f:cb66:35a9::/64). If more than one IP/network is specified for the destination, the source must be
            empty (any) or contain only a single IP/network. If IPv4 addresses and IPv6 addresses are mixed in destinations,
            sources must be empty (any).
        destination_ports (str | Unset): Valid configurations are any port (null), single port (f.e. 1234) or port range
            (f.e. 1024-65535).
    """

    direction: FirewallRuleDirection
    protocol: FirewallProtocol
    action: FirewallAction
    number_of_effective_rules: int | Unset = UNSET
    description: None | str | Unset = UNSET
    sources: list[str] | Unset = UNSET
    source_ports: str | Unset = UNSET
    destinations: list[str] | Unset = UNSET
    destination_ports: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        direction = self.direction.value

        protocol = self.protocol.value

        action = self.action.value

        number_of_effective_rules = self.number_of_effective_rules

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        sources: list[str] | Unset = UNSET
        if not isinstance(self.sources, Unset):
            sources = self.sources

        source_ports = self.source_ports

        destinations: list[str] | Unset = UNSET
        if not isinstance(self.destinations, Unset):
            destinations = self.destinations

        destination_ports = self.destination_ports

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "direction": direction,
                "protocol": protocol,
                "action": action,
            }
        )
        if number_of_effective_rules is not UNSET:
            field_dict["numberOfEffectiveRules"] = number_of_effective_rules
        if description is not UNSET:
            field_dict["description"] = description
        if sources is not UNSET:
            field_dict["sources"] = sources
        if source_ports is not UNSET:
            field_dict["sourcePorts"] = source_ports
        if destinations is not UNSET:
            field_dict["destinations"] = destinations
        if destination_ports is not UNSET:
            field_dict["destinationPorts"] = destination_ports

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        direction = FirewallRuleDirection(d.pop("direction"))

        protocol = FirewallProtocol(d.pop("protocol"))

        action = FirewallAction(d.pop("action"))

        number_of_effective_rules = d.pop("numberOfEffectiveRules", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        sources = cast(list[str], d.pop("sources", UNSET))

        source_ports = d.pop("sourcePorts", UNSET)

        destinations = cast(list[str], d.pop("destinations", UNSET))

        destination_ports = d.pop("destinationPorts", UNSET)

        firewall_rule = cls(
            direction=direction,
            protocol=protocol,
            action=action,
            number_of_effective_rules=number_of_effective_rules,
            description=description,
            sources=sources,
            source_ports=source_ports,
            destinations=destinations,
            destination_ports=destination_ports,
        )

        firewall_rule.additional_properties = d
        return firewall_rule

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
