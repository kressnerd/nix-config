from enum import Enum


class OsOptimization(str, Enum):
    BSD = "BSD"
    LINUX = "LINUX"
    LINUX_LEGACY = "LINUX_LEGACY"
    UNKNOWN = "UNKNOWN"
    WINDOWS = "WINDOWS"

    def __str__(self) -> str:
        return str(self.value)
