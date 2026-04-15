from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.failover_i_pv_6 import FailoverIPv6
from ...types import Unset


def _get_kwargs(
    user_id: int,
    *,
    ip: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["ip"] = ip

    params["serverId"] = server_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/users/{user_id}/failoverips/v6".format(
            user_id=user_id,
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> list[FailoverIPv6] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = FailoverIPv6.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[list[FailoverIPv6]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    ip: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
) -> Response[list[FailoverIPv6]]:
    """Get all failover IPv6s of this user.

    Args:
        user_id (int):
        ip (str | Unset):
        server_id (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[FailoverIPv6]]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        ip=ip,
        server_id=server_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    ip: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
) -> list[FailoverIPv6] | None:
    """Get all failover IPv6s of this user.

    Args:
        user_id (int):
        ip (str | Unset):
        server_id (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[FailoverIPv6]
    """

    return sync_detailed(
        user_id=user_id,
        client=client,
        ip=ip,
        server_id=server_id,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    ip: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
) -> Response[list[FailoverIPv6]]:
    """Get all failover IPv6s of this user.

    Args:
        user_id (int):
        ip (str | Unset):
        server_id (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[FailoverIPv6]]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        ip=ip,
        server_id=server_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    ip: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
) -> list[FailoverIPv6] | None:
    """Get all failover IPv6s of this user.

    Args:
        user_id (int):
        ip (str | Unset):
        server_id (int | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[FailoverIPv6]
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            client=client,
            ip=ip,
            server_id=server_id,
        )
    ).parsed
