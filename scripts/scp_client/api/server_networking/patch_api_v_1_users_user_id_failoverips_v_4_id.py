from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.response_error import ResponseError
from ...models.route_failover_ip import RouteFailoverIp
from ...models.task_info import TaskInfo


def _get_kwargs(
    user_id: int,
    id: int,
    *,
    body: RouteFailoverIp,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/api/v1/users/{user_id}/failoverips/v4/{id}".format(
            user_id=user_id,
            id=id,
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ResponseError | TaskInfo | None:
    if response.status_code == 202:
        response_202 = TaskInfo.from_dict(response.json())

        return response_202

    if response.status_code == 400:
        response_400 = ResponseError.from_dict(response.json())

        return response_400

    if response.status_code == 404:
        response_404 = ResponseError.from_dict(response.json())

        return response_404

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
    user_id: int,
    id: int,
    *,
    client: AuthenticatedClient | Client,
    body: RouteFailoverIp,
) -> Response[ResponseError | TaskInfo]:
    """Route a failover IPv4.

    Args:
        user_id (int):
        id (int):
        body (RouteFailoverIp):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        id=id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    id: int,
    *,
    client: AuthenticatedClient | Client,
    body: RouteFailoverIp,
) -> ResponseError | TaskInfo | None:
    """Route a failover IPv4.

    Args:
        user_id (int):
        id (int):
        body (RouteFailoverIp):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ResponseError | TaskInfo
    """

    return sync_detailed(
        user_id=user_id,
        id=id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    id: int,
    *,
    client: AuthenticatedClient | Client,
    body: RouteFailoverIp,
) -> Response[ResponseError | TaskInfo]:
    """Route a failover IPv4.

    Args:
        user_id (int):
        id (int):
        body (RouteFailoverIp):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        id=id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    id: int,
    *,
    client: AuthenticatedClient | Client,
    body: RouteFailoverIp,
) -> ResponseError | TaskInfo | None:
    """Route a failover IPv4.

    Args:
        user_id (int):
        id (int):
        body (RouteFailoverIp):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ResponseError | TaskInfo
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            id=id,
            client=client,
            body=body,
        )
    ).parsed
