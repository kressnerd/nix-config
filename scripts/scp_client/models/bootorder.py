from enum import Enum


class Bootorder(str, Enum):
    CDROM = "CDROM"
    HDD = "HDD"
    NETWORK = "NETWORK"

    def __str__(self) -> str:
        return str(self.value)
