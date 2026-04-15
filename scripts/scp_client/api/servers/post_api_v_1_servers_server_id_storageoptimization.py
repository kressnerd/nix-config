from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.response_error import ResponseError
from ...models.task_info import TaskInfo
from ...types import Unset


def _get_kwargs(
    server_id: int,
    *,
    disks: list[str] | Unset = UNSET,
    start_after_optimization: bool | Unset = False,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    json_disks: list[str] | Unset = UNSET
    if not isinstance(disks, Unset):
        json_disks = disks

    params["disks"] = json_disks

    params["startAfterOptimization"] = start_after_optimization

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/servers/{server_id}/storageoptimization".format(
            server_id=server_id,
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ResponseError | TaskInfo | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if response.status_code == 503:
        response_503 = ResponseError.from_dict(response.json())

        return response_503

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[ResponseError | TaskInfo]:
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
    disks: list[str] | Unset = UNSET,
    start_after_optimization: bool | Unset = False,
) -> Response[ResponseError | TaskInfo]:
    """Optimize storage of a server.

    Args:
        server_id (int):
        disks (list[str] | Unset):
        start_after_optimization (bool | Unset):  Default: False.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        disks=disks,
        start_after_optimization=start_after_optimization,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    disks: list[str] | Unset = UNSET,
    start_after_optimization: bool | Unset = False,
) -> ResponseError | TaskInfo | None:
    """Optimize storage of a server.

    Args:
        server_id (int):
        disks (list[str] | Unset):
        start_after_optimization (bool | Unset):  Default: False.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ResponseError | TaskInfo
    """

    return sync_detailed(
        server_id=server_id,
        client=client,
        disks=disks,
        start_after_optimization=start_after_optimization,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    disks: list[str] | Unset = UNSET,
    start_after_optimization: bool | Unset = False,
) -> Response[ResponseError | TaskInfo]:
    """Optimize storage of a server.

    Args:
        server_id (int):
        disks (list[str] | Unset):
        start_after_optimization (bool | Unset):  Default: False.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        disks=disks,
        start_after_optimization=start_after_optimization,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    disks: list[str] | Unset = UNSET,
    start_after_optimization: bool | Unset = False,
) -> ResponseError | TaskInfo | None:
    """Optimize storage of a server.

    Args:
        server_id (int):
        disks (list[str] | Unset):
        start_after_optimization (bool | Unset):  Default: False.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ResponseError | TaskInfo
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            client=client,
            disks=disks,
            start_after_optimization=start_after_optimization,
        )
    ).parsed
