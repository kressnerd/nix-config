from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.not_found_error import NotFoundError
from ...models.response_error import ResponseError
from ...models.task_info import TaskInfo


def _get_kwargs(
    server_id: int,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/api/v1/servers/{server_id}/rescuesystem".format(
            server_id=server_id,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> NotFoundError | ResponseError | TaskInfo | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if response.status_code == 400:
        response_400 = ResponseError.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = NotFoundError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[NotFoundError | ResponseError | TaskInfo]:
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
) -> Response[NotFoundError | ResponseError | TaskInfo]:
    """Deactivate rescue system for a server.

    Args:
        server_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> NotFoundError | ResponseError | TaskInfo | None:
    """Deactivate rescue system for a server.

    Args:
        server_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | ResponseError | TaskInfo
    """

    return sync_detailed(
        server_id=server_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> Response[NotFoundError | ResponseError | TaskInfo]:
    """Deactivate rescue system for a server.

    Args:
        server_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> NotFoundError | ResponseError | TaskInfo | None:
    """Deactivate rescue system for a server.

    Args:
        server_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | ResponseError | TaskInfo
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            client=client,
        )
    ).parsed
