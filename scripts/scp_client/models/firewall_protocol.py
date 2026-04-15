from enum import Enum


class FirewallProtocol(str, Enum):
    ICMP = "ICMP"
    ICMPV6 = "ICMPv6"
    TCP = "TCP"
    UDP = "UDP"

    def __str__(self) -> str:
        return str(self.value)
