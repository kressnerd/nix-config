from enum import Enum


class FirewallAction(str, Enum):
    ACCEPT = "ACCEPT"
    DROP = "DROP"

    def __str__(self) -> str:
        return str(self.value)
