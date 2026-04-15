from enum import Enum


class StorageOptimization(str, Enum):
    COMPAT = "COMPAT"
    FAST = "FAST"
    INCONSISTENT = "INCONSISTENT"
    NO = "NO"
    SLOW = "SLOW"

    def __str__(self) -> str:
        return str(self.value)
