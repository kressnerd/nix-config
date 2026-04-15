from enum import Enum


class ServerIpType(str, Enum):
    IP = "IP"
    ROUTED_IP = "ROUTED_IP"

    def __str__(self) -> str:
        return str(self.value)
