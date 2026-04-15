from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.firewall_policy import FirewallPolicy
from ...models.firewall_policy_save import FirewallPolicySave
from ...models.response_error import ResponseError
from ...models.validation_error import ValidationError


def _get_kwargs(
    user_id: int,
    *,
    body: FirewallPolicySave,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/users/{user_id}/firewall-policies".format(
            user_id=user_id,
        ),
    }

    _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> FirewallPolicy | ResponseError | ValidationError | None:
    if response.status_code == 201:
        response_201 = FirewallPolicy.from_dict(response.json())

        return response_201

    if response.status_code == 400:
        response_400 = ResponseError.from_dict(response.json())

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
) -> Response[FirewallPolicy | ResponseError | ValidationError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: FirewallPolicySave,
) -> Response[FirewallPolicy | ResponseError | ValidationError]:
    """Create firewall policy

    Args:
        user_id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[FirewallPolicy | ResponseError | ValidationError]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: FirewallPolicySave,
) -> FirewallPolicy | ResponseError | ValidationError | None:
    """Create firewall policy

    Args:
        user_id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        FirewallPolicy | ResponseError | ValidationError
    """

    return sync_detailed(
        user_id=user_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: FirewallPolicySave,
) -> Response[FirewallPolicy | ResponseError | ValidationError]:
    """Create firewall policy

    Args:
        user_id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[FirewallPolicy | ResponseError | ValidationError]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    *,
    client: AuthenticatedClient | Client,
    body: FirewallPolicySave,
) -> FirewallPolicy | ResponseError | ValidationError | None:
    """Create firewall policy

    Args:
        user_id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        FirewallPolicy | ResponseError | ValidationError
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            client=client,
            body=body,
        )
    ).parsed
