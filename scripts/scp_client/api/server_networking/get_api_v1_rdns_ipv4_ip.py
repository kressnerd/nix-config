from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.rdns import Rdns
from ...models.validation_error import ValidationError


def _get_kwargs(
    ip: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/rdns/ipv4/{ip}".format(
            ip=ip,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Rdns | ValidationError | None:
    if response.status_code == 200:
        response_200 = Rdns.from_dict(response.json())

        return response_200

    if response.status_code == 422:
        response_422 = ValidationError.from_dict(response.json())

        return response_422

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Rdns | ValidationError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    ip: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Rdns | ValidationError]:
    """Get rDNS for an IPv4.

    Args:
        ip (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Rdns | ValidationError]
    """

    kwargs = _get_kwargs(
        ip=ip,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    ip: str,
    *,
    client: AuthenticatedClient | Client,
) -> Rdns | ValidationError | None:
    """Get rDNS for an IPv4.

    Args:
        ip (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Rdns | ValidationError
    """

    return sync_detailed(
        ip=ip,
        client=client,
    ).parsed


async def asyncio_detailed(
    ip: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[Rdns | ValidationError]:
    """Get rDNS for an IPv4.

    Args:
        ip (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Rdns | ValidationError]
    """

    kwargs = _get_kwargs(
        ip=ip,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    ip: str,
    *,
    client: AuthenticatedClient | Client,
) -> Rdns | ValidationError | None:
    """Get rDNS for an IPv4.

    Args:
        ip (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Rdns | ValidationError
    """

    return (
        await asyncio_detailed(
            ip=ip,
            client=client,
        )
    ).parsed
