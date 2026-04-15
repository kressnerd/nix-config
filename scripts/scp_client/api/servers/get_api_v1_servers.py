from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.server_list_minimal import ServerListMinimal
from ...types import Unset


def _get_kwargs(
    *,
    firewall_policy_id: int | Unset = UNSET,
    ip: str | Unset = UNSET,
    limit: int | Unset = UNSET,
    name: str | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["firewallPolicyId"] = firewall_policy_id

    params["ip"] = ip

    params["limit"] = limit

    params["name"] = name

    params["offset"] = offset

    params["q"] = q

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/servers",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> list[ServerListMinimal] | None:
    if response.status_code == 200:
        response_200 = []
        _response_200 = response.json()
        for response_200_item_data in _response_200:
            response_200_item = ServerListMinimal.from_dict(response_200_item_data)

            response_200.append(response_200_item)

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[list[ServerListMinimal]]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
    firewall_policy_id: int | Unset = UNSET,
    ip: str | Unset = UNSET,
    limit: int | Unset = UNSET,
    name: str | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
) -> Response[list[ServerListMinimal]]:
    """Get servers

    Args:
        firewall_policy_id (int | Unset):
        ip (str | Unset):
        limit (int | Unset):
        name (str | Unset):
        offset (int | Unset):
        q (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[ServerListMinimal]]
    """

    kwargs = _get_kwargs(
        firewall_policy_id=firewall_policy_id,
        ip=ip,
        limit=limit,
        name=name,
        offset=offset,
        q=q,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
    firewall_policy_id: int | Unset = UNSET,
    ip: str | Unset = UNSET,
    limit: int | Unset = UNSET,
    name: str | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
) -> list[ServerListMinimal] | None:
    """Get servers

    Args:
        firewall_policy_id (int | Unset):
        ip (str | Unset):
        limit (int | Unset):
        name (str | Unset):
        offset (int | Unset):
        q (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[ServerListMinimal]
    """

    return sync_detailed(
        client=client,
        firewall_policy_id=firewall_policy_id,
        ip=ip,
        limit=limit,
        name=name,
        offset=offset,
        q=q,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
    firewall_policy_id: int | Unset = UNSET,
    ip: str | Unset = UNSET,
    limit: int | Unset = UNSET,
    name: str | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
) -> Response[list[ServerListMinimal]]:
    """Get servers

    Args:
        firewall_policy_id (int | Unset):
        ip (str | Unset):
        limit (int | Unset):
        name (str | Unset):
        offset (int | Unset):
        q (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[list[ServerListMinimal]]
    """

    kwargs = _get_kwargs(
        firewall_policy_id=firewall_policy_id,
        ip=ip,
        limit=limit,
        name=name,
        offset=offset,
        q=q,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
    firewall_policy_id: int | Unset = UNSET,
    ip: str | Unset = UNSET,
    limit: int | Unset = UNSET,
    name: str | Unset = UNSET,
    offset: int | Unset = UNSET,
    q: str | Unset = UNSET,
) -> list[ServerListMinimal] | None:
    """Get servers

    Args:
        firewall_policy_id (int | Unset):
        ip (str | Unset):
        limit (int | Unset):
        name (str | Unset):
        offset (int | Unset):
        q (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        list[ServerListMinimal]
    """

    return (
        await asyncio_detailed(
            client=client,
            firewall_policy_id=firewall_policy_id,
            ip=ip,
            limit=limit,
            name=name,
            offset=offset,
            q=q,
        )
    ).parsed
