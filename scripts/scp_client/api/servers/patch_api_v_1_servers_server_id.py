from http import HTTPStatus
from typing import Any, cast

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.response_error import ResponseError
from ...models.server_autostart_patch import ServerAutostartPatch
from ...models.server_bootorder_patch import ServerBootorderPatch
from ...models.server_cpu_topology_patch import ServerCpuTopologyPatch
from ...models.server_hostname_patch import ServerHostnamePatch
from ...models.server_keyboard_layout_patch import ServerKeyboardLayoutPatch
from ...models.server_nickname_patch import ServerNicknamePatch
from ...models.server_os_optimization_patch import ServerOsOptimizationPatch
from ...models.server_set_root_password_patch import ServerSetRootPasswordPatch
from ...models.server_state_patch import ServerStatePatch
from ...models.server_uefi_patch import ServerUEFIPatch
from ...models.task_info import TaskInfo
from ...types import Unset


def _get_kwargs(
    server_id: int,
    *,
    body: ServerAutostartPatch
    | ServerBootorderPatch
    | ServerCpuTopologyPatch
    | ServerHostnamePatch
    | ServerKeyboardLayoutPatch
    | ServerNicknamePatch
    | ServerOsOptimizationPatch
    | ServerSetRootPasswordPatch
    | ServerStatePatch
    | ServerUEFIPatch,
    state_option: str | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    params: dict[str, Any] = {}

    params["stateOption"] = state_option

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/api/v1/servers/{server_id}".format(
            server_id=server_id,
        ),
        "params": params,
    }

    _kwargs["json"]: dict[str, Any]
    if isinstance(body, ServerStatePatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerAutostartPatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerBootorderPatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerOsOptimizationPatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerCpuTopologyPatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerUEFIPatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerHostnamePatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerNicknamePatch):
        _kwargs["json"] = body.to_dict()
    elif isinstance(body, ServerKeyboardLayoutPatch):
        _kwargs["json"] = body.to_dict()
    else:
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/merge-patch+json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | ResponseError | TaskInfo | None:
    if response.status_code == 200:
        response_200 = cast(Any, None)
        return response_200

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
) -> Response[Any | ResponseError | TaskInfo]:
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
    body: ServerAutostartPatch
    | ServerBootorderPatch
    | ServerCpuTopologyPatch
    | ServerHostnamePatch
    | ServerKeyboardLayoutPatch
    | ServerNicknamePatch
    | ServerOsOptimizationPatch
    | ServerSetRootPasswordPatch
    | ServerStatePatch
    | ServerUEFIPatch,
    state_option: str | Unset = UNSET,
) -> Response[Any | ResponseError | TaskInfo]:
    """Start - stop server or update attributes like hostname, nickname, uefi, bootorder, ...

     Only one attribute at a time.

    Args:
        server_id (int):
        state_option (str | Unset):
        body (ServerAutostartPatch | ServerBootorderPatch | ServerCpuTopologyPatch |
            ServerHostnamePatch | ServerKeyboardLayoutPatch | ServerNicknamePatch |
            ServerOsOptimizationPatch | ServerSetRootPasswordPatch | ServerStatePatch |
            ServerUEFIPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        body=body,
        state_option=state_option,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: ServerAutostartPatch
    | ServerBootorderPatch
    | ServerCpuTopologyPatch
    | ServerHostnamePatch
    | ServerKeyboardLayoutPatch
    | ServerNicknamePatch
    | ServerOsOptimizationPatch
    | ServerSetRootPasswordPatch
    | ServerStatePatch
    | ServerUEFIPatch,
    state_option: str | Unset = UNSET,
) -> Any | ResponseError | TaskInfo | None:
    """Start - stop server or update attributes like hostname, nickname, uefi, bootorder, ...

     Only one attribute at a time.

    Args:
        server_id (int):
        state_option (str | Unset):
        body (ServerAutostartPatch | ServerBootorderPatch | ServerCpuTopologyPatch |
            ServerHostnamePatch | ServerKeyboardLayoutPatch | ServerNicknamePatch |
            ServerOsOptimizationPatch | ServerSetRootPasswordPatch | ServerStatePatch |
            ServerUEFIPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | ResponseError | TaskInfo
    """

    return sync_detailed(
        server_id=server_id,
        client=client,
        body=body,
        state_option=state_option,
    ).parsed


async def asyncio_detailed(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: ServerAutostartPatch
    | ServerBootorderPatch
    | ServerCpuTopologyPatch
    | ServerHostnamePatch
    | ServerKeyboardLayoutPatch
    | ServerNicknamePatch
    | ServerOsOptimizationPatch
    | ServerSetRootPasswordPatch
    | ServerStatePatch
    | ServerUEFIPatch,
    state_option: str | Unset = UNSET,
) -> Response[Any | ResponseError | TaskInfo]:
    """Start - stop server or update attributes like hostname, nickname, uefi, bootorder, ...

     Only one attribute at a time.

    Args:
        server_id (int):
        state_option (str | Unset):
        body (ServerAutostartPatch | ServerBootorderPatch | ServerCpuTopologyPatch |
            ServerHostnamePatch | ServerKeyboardLayoutPatch | ServerNicknamePatch |
            ServerOsOptimizationPatch | ServerSetRootPasswordPatch | ServerStatePatch |
            ServerUEFIPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | ResponseError | TaskInfo]
    """

    kwargs = _get_kwargs(
        server_id=server_id,
        body=body,
        state_option=state_option,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    server_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: ServerAutostartPatch
    | ServerBootorderPatch
    | ServerCpuTopologyPatch
    | ServerHostnamePatch
    | ServerKeyboardLayoutPatch
    | ServerNicknamePatch
    | ServerOsOptimizationPatch
    | ServerSetRootPasswordPatch
    | ServerStatePatch
    | ServerUEFIPatch,
    state_option: str | Unset = UNSET,
) -> Any | ResponseError | TaskInfo | None:
    """Start - stop server or update attributes like hostname, nickname, uefi, bootorder, ...

     Only one attribute at a time.

    Args:
        server_id (int):
        state_option (str | Unset):
        body (ServerAutostartPatch | ServerBootorderPatch | ServerCpuTopologyPatch |
            ServerHostnamePatch | ServerKeyboardLayoutPatch | ServerNicknamePatch |
            ServerOsOptimizationPatch | ServerSetRootPasswordPatch | ServerStatePatch |
            ServerUEFIPatch):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | ResponseError | TaskInfo
    """

    return (
        await asyncio_detailed(
            server_id=server_id,
            client=client,
            body=body,
            state_option=state_option,
        )
    ).parsed
