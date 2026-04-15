from enum import Enum


class NetworkDriver(str, Enum):
    E1000 = "E1000"
    E1000E = "E1000E"
    RTL8139 = "RTL8139"
    VIRTIO = "VIRTIO"
    VMXNET3 = "VMXNET3"

    def __str__(self) -> str:
        return str(self.value)
