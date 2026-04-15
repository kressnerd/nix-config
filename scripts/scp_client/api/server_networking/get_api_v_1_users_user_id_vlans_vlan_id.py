from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.not_found_error import NotFoundError
from ...models.v_lan import VLan


def _get_kwargs(
    user_id: int,
    vlan_id: int,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/users/{user_id}/vlans/{vlan_id}".format(
            user_id=user_id,
            vlan_id=vlan_id,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> NotFoundError | VLan | None:
    if response.status_code == 200:
        response_200 = VLan.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = NotFoundError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[NotFoundError | VLan]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    user_id: int,
    vlan_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> Response[NotFoundError | VLan]:
    """Get a VLan of a user

    Args:
        user_id (int):
        vlan_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | VLan]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        vlan_id=vlan_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    vlan_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> NotFoundError | VLan | None:
    """Get a VLan of a user

    Args:
        user_id (int):
        vlan_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | VLan
    """

    return sync_detailed(
        user_id=user_id,
        vlan_id=vlan_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    vlan_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> Response[NotFoundError | VLan]:
    """Get a VLan of a user

    Args:
        user_id (int):
        vlan_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[NotFoundError | VLan]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        vlan_id=vlan_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    vlan_id: int,
    *,
    client: AuthenticatedClient | Client,
) -> NotFoundError | VLan | None:
    """Get a VLan of a user

    Args:
        user_id (int):
        vlan_id (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        NotFoundError | VLan
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            vlan_id=vlan_id,
            client=client,
        )
    ).parsed
