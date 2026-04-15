from http import HTTPStatus
from typing import Any, cast

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.not_found_error import NotFoundError
from ...models.response_error import ResponseError
from ...models.v_lan_save import VLanSave


def _get_kwargs(
    user_id: int,
    vlan_id: int,
    *,
    body: VLanSave,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/api/v1/users/{user_id}/vlans/{vlan_id}".format(
            user_id=user_id,
            vlan_id=vlan_id,
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | NotFoundError | ResponseError | None:
    if response.status_code == 202:
        response_202 = cast(Any, None)
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
) -> Response[Any | NotFoundError | ResponseError]:
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
    body: VLanSave,
) -> Response[Any | NotFoundError | ResponseError]:
    """Update a VLan

    Args:
        user_id (int):
        vlan_id (int):
        body (VLanSave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | NotFoundError | ResponseError]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        vlan_id=vlan_id,
        body=body,
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
    body: VLanSave,
) -> Any | NotFoundError | ResponseError | None:
    """Update a VLan

    Args:
        user_id (int):
        vlan_id (int):
        body (VLanSave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | NotFoundError | ResponseError
    """

    return sync_detailed(
        user_id=user_id,
        vlan_id=vlan_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    vlan_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: VLanSave,
) -> Response[Any | NotFoundError | ResponseError]:
    """Update a VLan

    Args:
        user_id (int):
        vlan_id (int):
        body (VLanSave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | NotFoundError | ResponseError]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        vlan_id=vlan_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    vlan_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: VLanSave,
) -> Any | NotFoundError | ResponseError | None:
    """Update a VLan

    Args:
        user_id (int):
        vlan_id (int):
        body (VLanSave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | NotFoundError | ResponseError
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            vlan_id=vlan_id,
            client=client,
            body=body,
        )
    ).parsed
