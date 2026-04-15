"""A client library for accessing SCP (Server Control Panel) REST API"""

from .client import AuthenticatedClient, Client

__all__ = (
    "AuthenticatedClient",
    "Client",
)
