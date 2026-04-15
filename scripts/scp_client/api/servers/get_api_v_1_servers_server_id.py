from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.not_found_error import NotFoundError
from ...models.server import Server
from ...types import Unset


def _get_kwargs(
    server_id: int,
    *,
    load_server_live_info: bool | Unset = True,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["loadServerLiveInfo"] = load_server_live_info

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/servers/{server_id}".format(
            server_id=server_id,
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> NotFoundError | Server | None:
    if response.status_code == 200:
        response_200 = Server.from_dict(response.json())

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
) -> Response[NotFoundError | Server]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    load_server_live_info: bool | Unset = True,
) -> Response[NotFoundError | Server]:
    """Get one server

    Args:
        server_id (int):
        load_server_live_info (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | Server]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        load_server_live_info=load_server_live_info,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    load_server_live_info: bool | Unset = True,
) -> NotFoundError | Server | None:
    """Get one server

    Args:
        server_id (int):
        load_server_live_info (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | Server
    """

    return sync_detailed(
        server_id=server_id,
        client=client,
        load_server_live_info=load_server_live_info,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    load_server_live_info: bool | Unset = True,
) -> Response[NotFoundError | Server]:
    """Get one server

    Args:
        server_id (int):
        load_server_live_info (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | Server]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        load_server_live_info=load_server_live_info,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    load_server_live_info: bool | Unset = True,
) -> NotFoundError | Server | None:
    """Get one server

    Args:
        server_id (int):
        load_server_live_info (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | Server
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            client=client,
            load_server_live_info=load_server_live_info,
        )
    ).parsed
