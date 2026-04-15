from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.interface import Interface
from ...models.not_found_error import NotFoundError
from ...types import Unset


def _get_kwargs(
    server_id: int,
    mac: str,
    *,
    load_rdns: bool | Unset = True,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["loadRdns"] = load_rdns

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/servers/{server_id}/interfaces/{mac}".format(
            server_id=server_id,
            mac=mac,
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Interface | NotFoundError | None:
    if response.status_code == 200:
        response_200 = Interface.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = NotFoundError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Interface | NotFoundError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
    load_rdns: bool | Unset = True,
) -> Response[Interface | NotFoundError]:
    """Get an interface and IPs of a server including routed IPs and rDNS entries.

    Args:
        server_id (int):
        mac (str):
        load_rdns (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Interface | NotFoundError]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        mac=mac,
        load_rdns=load_rdns,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
    load_rdns: bool | Unset = True,
) -> Interface | NotFoundError | None:
    """Get an interface and IPs of a server including routed IPs and rDNS entries.

    Args:
        server_id (int):
        mac (str):
        load_rdns (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Interface | NotFoundError
    """

    return sync_detailed(
        server_id=server_id,
        mac=mac,
        client=client,
        load_rdns=load_rdns,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
    load_rdns: bool | Unset = True,
) -> Response[Interface | NotFoundError]:
    """Get an interface and IPs of a server including routed IPs and rDNS entries.

    Args:
        server_id (int):
        mac (str):
        load_rdns (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Interface | NotFoundError]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        mac=mac,
        load_rdns=load_rdns,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
    load_rdns: bool | Unset = True,
) -> Interface | NotFoundError | None:
    """Get an interface and IPs of a server including routed IPs and rDNS entries.

    Args:
        server_id (int):
        mac (str):
        load_rdns (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Interface | NotFoundError
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            mac=mac,
            client=client,
            load_rdns=load_rdns,
        )
    ).parsed
