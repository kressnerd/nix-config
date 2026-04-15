from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.task_info import TaskInfo


def _get_kwargs(
    server_id: int,
    mac: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/servers/{server_id}/interfaces/{mac}/firewall:reapply".format(
            server_id=server_id,
            mac=mac,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> TaskInfo | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[TaskInfo]:
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
) -> Response[TaskInfo]:
    """Reapply firewall. Necessary if policy update timed out due to long running write operation on server
    (f.e. storage optimization)

    Args:
        server_id (int):
        mac (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        mac=mac,
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
) -> TaskInfo | None:
    """Reapply firewall. Necessary if policy update timed out due to long running write operation on server
    (f.e. storage optimization)

    Args:
        server_id (int):
        mac (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        TaskInfo
    """

    return sync_detailed(
        server_id=server_id,
        mac=mac,
        client=client,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[TaskInfo]:
    """Reapply firewall. Necessary if policy update timed out due to long running write operation on server
    (f.e. storage optimization)

    Args:
        server_id (int):
        mac (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        mac=mac,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    mac: str,
    *,
    client: AuthenticatedClient | Client,
) -> TaskInfo | None:
    """Reapply firewall. Necessary if policy update timed out due to long running write operation on server
    (f.e. storage optimization)

    Args:
        server_id (int):
        mac (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        TaskInfo
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            mac=mac,
            client=client,
        )
    ).parsed
