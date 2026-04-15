from enum import Enum


class StorageDriver(str, Enum):
    IDE = "IDE"
    SATA = "SATA"
    VIRTIO = "VIRTIO"
    VIRTIO_SCSI = "VIRTIO_SCSI"

    def __str__(self) -> str:
        return str(self.value)
