from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.server_create_nic_vlan import ServerCreateNicVlan
from ...models.task_info import TaskInfo
from ...models.validation_error import ValidationError


def _get_kwargs(
    server_id: int,
    *,
    body: ServerCreateNicVlan,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/servers/{server_id}/interfaces".format(
            server_id=server_id,
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/merge-patch+json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> TaskInfo | ValidationError | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if response.status_code == 400:
        response_400 = ValidationError.from_dict(response.json())

        return response_400

    if response.status_code == 422:
        response_422 = ValidationError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[TaskInfo | ValidationError]:
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
    body: ServerCreateNicVlan,
) -> Response[TaskInfo | ValidationError]:
    """Create an interface in a server.

    Args:
        server_id (int):
        body (ServerCreateNicVlan):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[TaskInfo | ValidationError]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: ServerCreateNicVlan,
) -> TaskInfo | ValidationError | None:
    """Create an interface in a server.

    Args:
        server_id (int):
        body (ServerCreateNicVlan):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        TaskInfo | ValidationError
    """

    return sync_detailed(
        server_id=server_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: ServerCreateNicVlan,
) -> Response[TaskInfo | ValidationError]:
    """Create an interface in a server.

    Args:
        server_id (int):
        body (ServerCreateNicVlan):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[TaskInfo | ValidationError]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: ServerCreateNicVlan,
) -> TaskInfo | ValidationError | None:
    """Create an interface in a server.

    Args:
        server_id (int):
        body (ServerCreateNicVlan):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        TaskInfo | ValidationError
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            client=client,
            body=body,
        )
    ).parsed
