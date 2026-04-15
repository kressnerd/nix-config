from enum import Enum


class ServerState1(str, Enum):
    OFF = "OFF"
    ON = "ON"
    SUSPENDED = "SUSPENDED"

    def __str__(self) -> str:
        return str(self.value)
