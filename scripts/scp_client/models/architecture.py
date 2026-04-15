from enum import Enum


class Architecture(str, Enum):
    AMD64 = "AMD64"
    ARM64 = "ARM64"

    def __str__(self) -> str:
        return str(self.value)
