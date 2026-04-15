from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.post_api_v1_openapi_mcp_response_200 import (
    PostApiV1OpenapiMcpResponse200,
)


def _get_kwargs() -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/openapi/mcp",
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> PostApiV1OpenapiMcpResponse200 | None:
    if response.status_code == 200:
        response_200 = PostApiV1OpenapiMcpResponse200.from_dict(response.json())

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[PostApiV1OpenapiMcpResponse200]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient | Client,
) -> Response[PostApiV1OpenapiMcpResponse200]:
    """SCP OpenAPI Spec MCP Server

     SCP (Server Control Panel) API Explorer - OpenAPI Specification Explorer for netcup SCP REST API -
    Provides comprehensive documentation, schema definitions, and implementation guidance for building
    SCP API clients and scripts. Does not execute API calls directly.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostApiV1OpenapiMcpResponse200]
    """

    kwargs = _get_kwargs()

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient | Client,
) -> PostApiV1OpenapiMcpResponse200 | None:
    """SCP OpenAPI Spec MCP Server

     SCP (Server Control Panel) API Explorer - OpenAPI Specification Explorer for netcup SCP REST API -
    Provides comprehensive documentation, schema definitions, and implementation guidance for building
    SCP API clients and scripts. Does not execute API calls directly.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostApiV1OpenapiMcpResponse200
    """

    return sync_detailed(
        client=client,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient | Client,
) -> Response[PostApiV1OpenapiMcpResponse200]:
    """SCP OpenAPI Spec MCP Server

     SCP (Server Control Panel) API Explorer - OpenAPI Specification Explorer for netcup SCP REST API -
    Provides comprehensive documentation, schema definitions, and implementation guidance for building
    SCP API clients and scripts. Does not execute API calls directly.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[PostApiV1OpenapiMcpResponse200]
    """

    kwargs = _get_kwargs()

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient | Client,
) -> PostApiV1OpenapiMcpResponse200 | None:
    """SCP OpenAPI Spec MCP Server

     SCP (Server Control Panel) API Explorer - OpenAPI Specification Explorer for netcup SCP REST API -
    Provides comprehensive documentation, schema definitions, and implementation guidance for building
    SCP API clients and scripts. Does not execute API calls directly.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        PostApiV1OpenapiMcpResponse200
    """

    return (
        await asyncio_detailed(
            client=client,
        )
    ).parsed
