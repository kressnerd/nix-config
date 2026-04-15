from http import HTTPStatus
from typing import Any, cast

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.not_found_error import NotFoundError
from ...models.server_interface_update import ServerInterfaceUpdate
from ...models.task_info import TaskInfo


def _get_kwargs(
    server_id: int,
    mac: str,
    *,
    body: ServerInterfaceUpdate,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/api/v1/servers/{server_id}/interfaces/{mac}".format(
            server_id=server_id,
            mac=mac,
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | NotFoundError | TaskInfo | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if response.status_code == 204:
        response_204 = cast(Any, None)
        return response_204

    if response.status_code == 404:
        response_404 = NotFoundError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Any | NotFoundError | TaskInfo]:
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
    body: ServerInterfaceUpdate,
) -> Response[Any | NotFoundError | TaskInfo]:
    """Update interface attributes.

    Args:
        server_id (int):
        mac (str):
        body (ServerInterfaceUpdate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | NotFoundError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        mac=mac,
        body=body,
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
    body: ServerInterfaceUpdate,
) -> Any | NotFoundError | TaskInfo | None:
    """Update interface attributes.

    Args:
        server_id (int):
        mac (str):
        body (ServerInterfaceUpdate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | NotFoundError | TaskInfo
    """

    return sync_detailed(
        server_id=server_id,
        mac=mac,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
    body: ServerInterfaceUpdate,
) -> Response[Any | NotFoundError | TaskInfo]:
    """Update interface attributes.

    Args:
        server_id (int):
        mac (str):
        body (ServerInterfaceUpdate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | NotFoundError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        mac=mac,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
    body: ServerInterfaceUpdate,
) -> Any | NotFoundError | TaskInfo | None:
    """Update interface attributes.

    Args:
        server_id (int):
        mac (str):
        body (ServerInterfaceUpdate):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | NotFoundError | TaskInfo
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            mac=mac,
            client=client,
            body=body,
        )
    ).parsed
