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
    name: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/servers/{server_id}/snapshots/{name}/revert".format(
            server_id=server_id,
            name=name,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> NotFoundError | ResponseError | TaskInfo | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if response.status_code == 404:
        response_404 = NotFoundError.from_dict(response.json())

        return response_404

    if response.status_code == 503:
        response_503 = ResponseError.from_dict(response.json())

        return response_503

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
    name: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[NotFoundError | ResponseError | TaskInfo]:
    """Revert a snapshot of a server

    Args:
        server_id (int):
        name (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        name=name,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    name: str,
    *,
    client: AuthenticatedClient | Client,
) -> NotFoundError | ResponseError | TaskInfo | None:
    """Revert a snapshot of a server

    Args:
        server_id (int):
        name (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | ResponseError | TaskInfo
    """

    return sync_detailed(
        server_id=server_id,
        name=name,
        client=client,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    name: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[NotFoundError | ResponseError | TaskInfo]:
    """Revert a snapshot of a server

    Args:
        server_id (int):
        name (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        name=name,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    name: str,
    *,
    client: AuthenticatedClient | Client,
) -> NotFoundError | ResponseError | TaskInfo | None:
    """Revert a snapshot of a server

    Args:
        server_id (int):
        name (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | ResponseError | TaskInfo
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            name=name,
            client=client,
        )
    ).parsed
