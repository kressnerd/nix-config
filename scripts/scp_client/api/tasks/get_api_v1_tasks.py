from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.task_info_minimal import TaskInfoMinimal
from ...models.task_state import TaskState
from ...types import Unset


def _get_kwargs(
    *,
    limit: int | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
    state: TaskState | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["limit"] = limit

    params["offset"] = offset

    params["q"] = q

    params["serverId"] = server_id

    json_state: str | Unset = UNSET
    if not isinstance(state, Unset):
        json_state = state.value

    params["state"] = json_state

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/tasks",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> list[TaskInfoMinimal] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = TaskInfoMinimal.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[list[TaskInfoMinimal]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    limit: int | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
    state: TaskState | Unset = UNSET,
) -> Response[list[TaskInfoMinimal]]:
    """Get all tasks

    Args:
        limit (int | Unset):
        offset (int | Unset):
        q (str | Unset):
        server_id (int | Unset):
        state (TaskState | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[TaskInfoMinimal]]
    """

    kwargs = _get_kwargs(
        limit=limit,
        offset=offset,
        q=q,
        server_id=server_id,
        state=state,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    limit: int | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
    state: TaskState | Unset = UNSET,
) -> list[TaskInfoMinimal] | None:
    """Get all tasks

    Args:
        limit (int | Unset):
        offset (int | Unset):
        q (str | Unset):
        server_id (int | Unset):
        state (TaskState | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[TaskInfoMinimal]
    """

    return sync_detailed(
        client=client,
        limit=limit,
        offset=offset,
        q=q,
        server_id=server_id,
        state=state,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    limit: int | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
    state: TaskState | Unset = UNSET,
) -> Response[list[TaskInfoMinimal]]:
    """Get all tasks

    Args:
        limit (int | Unset):
        offset (int | Unset):
        q (str | Unset):
        server_id (int | Unset):
        state (TaskState | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[TaskInfoMinimal]]
    """

    kwargs = _get_kwargs(
        limit=limit,
        offset=offset,
        q=q,
        server_id=server_id,
        state=state,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    limit: int | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
    server_id: int | Unset = UNSET,
    state: TaskState | Unset = UNSET,
) -> list[TaskInfoMinimal] | None:
    """Get all tasks

    Args:
        limit (int | Unset):
        offset (int | Unset):
        q (str | Unset):
        server_id (int | Unset):
        state (TaskState | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[TaskInfoMinimal]
    """

    return (
        await asyncio_detailed(
            client=client,
            limit=limit,
            offset=offset,
            q=q,
            server_id=server_id,
            state=state,
        )
    ).parsed
