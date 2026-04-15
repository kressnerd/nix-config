from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.firewall_policy_save import FirewallPolicySave
from ...models.firewall_policy_update_result import FirewallPolicyUpdateResult
from ...models.response_error import ResponseError
from ...models.validation_error import ValidationError


def _get_kwargs(
    user_id: int,
    id: int,
    *,
    body: FirewallPolicySave,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/api/v1/users/{user_id}/firewall-policies/{id}".format(
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
) -> FirewallPolicyUpdateResult | ResponseError | ValidationError | None:
    if response.status_code == 202:
        response_202 = FirewallPolicyUpdateResult.from_dict(response.json())

        return response_202

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
) -> Response[FirewallPolicyUpdateResult | ResponseError | ValidationError]:
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
    body: FirewallPolicySave,
) -> Response[FirewallPolicyUpdateResult | ResponseError | ValidationError]:
    """Update firewall policy

    Args:
        user_id (int):
        id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[FirewallPolicyUpdateResult | ResponseError | ValidationError]
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
    body: FirewallPolicySave,
) -> FirewallPolicyUpdateResult | ResponseError | ValidationError | None:
    """Update firewall policy

    Args:
        user_id (int):
        id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        FirewallPolicyUpdateResult | ResponseError | ValidationError
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
    body: FirewallPolicySave,
) -> Response[FirewallPolicyUpdateResult | ResponseError | ValidationError]:
    """Update firewall policy

    Args:
        user_id (int):
        id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[FirewallPolicyUpdateResult | ResponseError | ValidationError]
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
    body: FirewallPolicySave,
) -> FirewallPolicyUpdateResult | ResponseError | ValidationError | None:
    """Update firewall policy

    Args:
        user_id (int):
        id (int):
        body (FirewallPolicySave):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        FirewallPolicyUpdateResult | ResponseError | ValidationError
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            id=id,
            client=client,
            body=body,
        )
    ).parsed
