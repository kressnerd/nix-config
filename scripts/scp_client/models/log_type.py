from enum import Enum


class LogType(str, Enum):
    ERROR = "ERROR"
    INFO = "INFO"
    WARNING = "WARNING"

    def __str__(self) -> str:
        return str(self.value)
