from enum import Enum


class ImplicitRule(str, Enum):
    ACCEPT_ALL = "ACCEPT_ALL"
    DROP_ALL = "DROP_ALL"

    def __str__(self) -> str:
        return str(self.value)
