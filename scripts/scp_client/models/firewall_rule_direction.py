from enum import Enum


class FirewallRuleDirection(str, Enum):
    EGRESS = "EGRESS"
    INGRESS = "INGRESS"

    def __str__(self) -> str:
        return str(self.value)
