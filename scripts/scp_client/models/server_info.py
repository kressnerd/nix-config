from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.bootorder import Bootorder
from ..models.os_optimization import OsOptimization
from ..models.server_state import ServerState
from ..models.storage_optimization import StorageOptimization
from typing import cast

if TYPE_CHECKING:
    from ..models.server_disk import ServerDisk
    from ..models.server_interface import ServerInterface


T = TypeVar("T", bound="ServerInfo")


@_attrs_define
class ServerInfo:
    """
    Attributes:
        state (ServerState | Unset):
        autostart (bool | Unset):
        uefi (bool | Unset):
        interfaces (list[ServerInterface] | Unset):
        disks (list[ServerDisk] | Unset):
        bootorder (list[Bootorder] | Unset):
        required_storage_optimization (StorageOptimization | Unset):
        template (None | str | Unset):
        uptime_in_seconds (int | Unset):
        current_server_memory_in_mi_b (int | Unset):
        max_server_memory_in_mi_b (int | Unset):
        cpu_count (int | Unset):
        cpu_max_count (int | Unset):
        sockets (int | Unset):
        cores_per_socket (int | Unset):
        latest_qemu (bool | Unset):
        config_changed (bool | Unset):
        os_optimization (OsOptimization | Unset):
        nested_guest (bool | Unset):
        machine_type (str | Unset):
        keyboard_layout (str | Unset):
        cloudinit_attached (bool | Unset):
    """

    state: ServerState | Unset = UNSET
    autostart: bool | Unset = UNSET
    uefi: bool | Unset = UNSET
    interfaces: list[ServerInterface] | Unset = UNSET
    disks: list[ServerDisk] | Unset = UNSET
    bootorder: list[Bootorder] | Unset = UNSET
    required_storage_optimization: StorageOptimization | Unset = UNSET
    template: None | str | Unset = UNSET
    uptime_in_seconds: int | Unset = UNSET
    current_server_memory_in_mi_b: int | Unset = UNSET
    max_server_memory_in_mi_b: int | Unset = UNSET
    cpu_count: int | Unset = UNSET
    cpu_max_count: int | Unset = UNSET
    sockets: int | Unset = UNSET
    cores_per_socket: int | Unset = UNSET
    latest_qemu: bool | Unset = UNSET
    config_changed: bool | Unset = UNSET
    os_optimization: OsOptimization | Unset = UNSET
    nested_guest: bool | Unset = UNSET
    machine_type: str | Unset = UNSET
    keyboard_layout: str | Unset = UNSET
    cloudinit_attached: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        autostart = self.autostart

        uefi = self.uefi

        interfaces: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.interfaces, Unset):
            interfaces = []
            for interfaces_item_data in self.interfaces:
                interfaces_item = interfaces_item_data.to_dict()
                interfaces.append(interfaces_item)

        disks: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.disks, Unset):
            disks = []
            for disks_item_data in self.disks:
                disks_item = disks_item_data.to_dict()
                disks.append(disks_item)

        bootorder: list[str] | Unset = UNSET
        if not isinstance(self.bootorder, Unset):
            bootorder = []
            for bootorder_item_data in self.bootorder:
                bootorder_item = bootorder_item_data.value
                bootorder.append(bootorder_item)

        required_storage_optimization: str | Unset = UNSET
        if not isinstance(self.required_storage_optimization, Unset):
            required_storage_optimization = self.required_storage_optimization.value

        template: None | str | Unset
        if isinstance(self.template, Unset):
            template = UNSET
        else:
            template = self.template

        uptime_in_seconds = self.uptime_in_seconds

        current_server_memory_in_mi_b = self.current_server_memory_in_mi_b

        max_server_memory_in_mi_b = self.max_server_memory_in_mi_b

        cpu_count = self.cpu_count

        cpu_max_count = self.cpu_max_count

        sockets = self.sockets

        cores_per_socket = self.cores_per_socket

        latest_qemu = self.latest_qemu

        config_changed = self.config_changed

        os_optimization: str | Unset = UNSET
        if not isinstance(self.os_optimization, Unset):
            os_optimization = self.os_optimization.value

        nested_guest = self.nested_guest

        machine_type = self.machine_type

        keyboard_layout = self.keyboard_layout

        cloudinit_attached = self.cloudinit_attached

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if state is not UNSET:
            field_dict["state"] = state
        if autostart is not UNSET:
            field_dict["autostart"] = autostart
        if uefi is not UNSET:
            field_dict["uefi"] = uefi
        if interfaces is not UNSET:
            field_dict["interfaces"] = interfaces
        if disks is not UNSET:
            field_dict["disks"] = disks
        if bootorder is not UNSET:
            field_dict["bootorder"] = bootorder
        if required_storage_optimization is not UNSET:
            field_dict["requiredStorageOptimization"] = required_storage_optimization
        if template is not UNSET:
            field_dict["template"] = template
        if uptime_in_seconds is not UNSET:
            field_dict["uptimeInSeconds"] = uptime_in_seconds
        if current_server_memory_in_mi_b is not UNSET:
            field_dict["currentServerMemoryInMiB"] = current_server_memory_in_mi_b
        if max_server_memory_in_mi_b is not UNSET:
            field_dict["maxServerMemoryInMiB"] = max_server_memory_in_mi_b
        if cpu_count is not UNSET:
            field_dict["cpuCount"] = cpu_count
        if cpu_max_count is not UNSET:
            field_dict["cpuMaxCount"] = cpu_max_count
        if sockets is not UNSET:
            field_dict["sockets"] = sockets
        if cores_per_socket is not UNSET:
            field_dict["coresPerSocket"] = cores_per_socket
        if latest_qemu is not UNSET:
            field_dict["latestQemu"] = latest_qemu
        if config_changed is not UNSET:
            field_dict["configChanged"] = config_changed
        if os_optimization is not UNSET:
            field_dict["osOptimization"] = os_optimization
        if nested_guest is not UNSET:
            field_dict["nestedGuest"] = nested_guest
        if machine_type is not UNSET:
            field_dict["machineType"] = machine_type
        if keyboard_layout is not UNSET:
            field_dict["keyboardLayout"] = keyboard_layout
        if cloudinit_attached is not UNSET:
            field_dict["cloudinitAttached"] = cloudinit_attached

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.server_disk import ServerDisk
        from ..models.server_interface import ServerInterface

        d = dict(src_dict)
        _state = d.pop("state", UNSET)
        state: ServerState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = ServerState(_state)

        autostart = d.pop("autostart", UNSET)

        uefi = d.pop("uefi", UNSET)

        _interfaces = d.pop("interfaces", UNSET)
        interfaces: list[ServerInterface] | Unset = UNSET
        if _interfaces is not UNSET:
            interfaces = []
            for interfaces_item_data in _interfaces:
                interfaces_item = ServerInterface.from_dict(interfaces_item_data)

                interfaces.append(interfaces_item)

        _disks = d.pop("disks", UNSET)
        disks: list[ServerDisk] | Unset = UNSET
        if _disks is not UNSET:
            disks = []
            for disks_item_data in _disks:
                disks_item = ServerDisk.from_dict(disks_item_data)

                disks.append(disks_item)

        _bootorder = d.pop("bootorder", UNSET)
        bootorder: list[Bootorder] | Unset = UNSET
        if _bootorder is not UNSET:
            bootorder = []
            for bootorder_item_data in _bootorder:
                bootorder_item = Bootorder(bootorder_item_data)

                bootorder.append(bootorder_item)

        _required_storage_optimization = d.pop("requiredStorageOptimization", UNSET)
        required_storage_optimization: StorageOptimization | Unset
        if isinstance(_required_storage_optimization, Unset):
            required_storage_optimization = UNSET
        else:
            required_storage_optimization = StorageOptimization(
                _required_storage_optimization
            )

        def _parse_template(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        template = _parse_template(d.pop("template", UNSET))

        uptime_in_seconds = d.pop("uptimeInSeconds", UNSET)

        current_server_memory_in_mi_b = d.pop("currentServerMemoryInMiB", UNSET)

        max_server_memory_in_mi_b = d.pop("maxServerMemoryInMiB", UNSET)

        cpu_count = d.pop("cpuCount", UNSET)

        cpu_max_count = d.pop("cpuMaxCount", UNSET)

        sockets = d.pop("sockets", UNSET)

        cores_per_socket = d.pop("coresPerSocket", UNSET)

        latest_qemu = d.pop("latestQemu", UNSET)

        config_changed = d.pop("configChanged", UNSET)

        _os_optimization = d.pop("osOptimization", UNSET)
        os_optimization: OsOptimization | Unset
        if isinstance(_os_optimization, Unset):
            os_optimization = UNSET
        else:
            os_optimization = OsOptimization(_os_optimization)

        nested_guest = d.pop("nestedGuest", UNSET)

        machine_type = d.pop("machineType", UNSET)

        keyboard_layout = d.pop("keyboardLayout", UNSET)

        cloudinit_attached = d.pop("cloudinitAttached", UNSET)

        server_info = cls(
            state=state,
            autostart=autostart,
            uefi=uefi,
            interfaces=interfaces,
            disks=disks,
            bootorder=bootorder,
            required_storage_optimization=required_storage_optimization,
            template=template,
            uptime_in_seconds=uptime_in_seconds,
            current_server_memory_in_mi_b=current_server_memory_in_mi_b,
            max_server_memory_in_mi_b=max_server_memory_in_mi_b,
            cpu_count=cpu_count,
            cpu_max_count=cpu_max_count,
            sockets=sockets,
            cores_per_socket=cores_per_socket,
            latest_qemu=latest_qemu,
            config_changed=config_changed,
            os_optimization=os_optimization,
            nested_guest=nested_guest,
            machine_type=machine_type,
            keyboard_layout=keyboard_layout,
            cloudinit_attached=cloudinit_attached,
        )

        server_info.additional_properties = d
        return server_info

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
