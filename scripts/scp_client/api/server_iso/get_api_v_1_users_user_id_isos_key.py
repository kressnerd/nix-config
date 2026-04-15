from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.response_error import ResponseError
from ...models.s3_download_infos import S3DownloadInfos


def _get_kwargs(
    user_id: int,
    key: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/users/{user_id}/isos/{key}".format(
            user_id=user_id,
            key=key,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> ResponseError | S3DownloadInfos | None:
    if response.status_code == 200:
        response_200 = S3DownloadInfos.from_dict(response.json())

        return response_200

    if response.status_code == 404:
        response_404 = ResponseError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[ResponseError | S3DownloadInfos]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    user_id: int,
    key: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[ResponseError | S3DownloadInfos]:
    """Get presigned URL for an ISO

    Args:
        user_id (int):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ResponseError | S3DownloadInfos]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    key: str,
    *,
    client: AuthenticatedClient | Client,
) -> ResponseError | S3DownloadInfos | None:
    """Get presigned URL for an ISO

    Args:
        user_id (int):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ResponseError | S3DownloadInfos
    """

    return sync_detailed(
        user_id=user_id,
        key=key,
        client=client,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    key: str,
    *,
    client: AuthenticatedClient | Client,
) -> Response[ResponseError | S3DownloadInfos]:
    """Get presigned URL for an ISO

    Args:
        user_id (int):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[ResponseError | S3DownloadInfos]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    key: str,
    *,
    client: AuthenticatedClient | Client,
) -> ResponseError | S3DownloadInfos | None:
    """Get presigned URL for an ISO

    Args:
        user_id (int):
        key (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        ResponseError | S3DownloadInfos
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            key=key,
            client=client,
        )
    ).parsed
