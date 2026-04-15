from enum import Enum


class ServerState(str, Enum):
    BLOCKED = "BLOCKED"
    CRASHED = "CRASHED"
    DISK_SNAPSHOT = "DISK_SNAPSHOT"
    NOSTATE = "NOSTATE"
    PAUSED = "PAUSED"
    PMSUSPENDED = "PMSUSPENDED"
    RUNNING = "RUNNING"
    SHUTDOWN = "SHUTDOWN"
    SHUTOFF = "SHUTOFF"

    def __str__(self) -> str:
        return str(self.value)
