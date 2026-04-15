from enum import Enum


class TaskState(str, Enum):
    CANCELED = "CANCELED"
    ERROR = "ERROR"
    FINISHED = "FINISHED"
    PENDING = "PENDING"
    ROLLBACK = "ROLLBACK"
    RUNNING = "RUNNING"
    WAITING_FOR_CANCEL = "WAITING_FOR_CANCEL"

    def __str__(self) -> str:
        return str(self.value)
