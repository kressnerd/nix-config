from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response, UNSET
from ... import errors

from ...models.s3_upload import S3Upload
from ...types import Unset


def _get_kwargs(
    user_id: int,
    key: str,
    *,
    multipart: bool | Unset = True,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["multipart"] = multipart

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "post",
        "url": "/api/v1/users/{user_id}/images/{key}".format(
            user_id=user_id,
            key=key,
        ),
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> S3Upload | None:
    if response.status_code == 201:
        response_201 = S3Upload.from_dict(response.json())

        return response_201

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[S3Upload]:
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
    multipart: bool | Unset = True,
) -> Response[S3Upload]:
    r"""Prepares an upload for an image

     If \"multipart=true\", returns \"uploadId\" that is used to fetch upload URLs for each part with
     \"GET /api/v1/users/{userId}/images/{key}/{uploadId}/parts/{partNumber}\". Use this URL to upload
    individual parts and
     get an \"ETag\" for each part. To finish, call \"PUT
    /api/v1/users/{userId}/images/{key}/{uploadId}\"
     with the list of all uploaded parts, containing \"ETag\" and \"partNumber\" for each part. Part
    numbers start at 1.

    If \"multipart=false\", returns \"presignedUrl\" that is used to upload the image at once.

    Args:
        user_id (int):
        key (str):
        multipart (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[S3Upload]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
        multipart=multipart,
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
    multipart: bool | Unset = True,
) -> S3Upload | None:
    r"""Prepares an upload for an image

     If \"multipart=true\", returns \"uploadId\" that is used to fetch upload URLs for each part with
     \"GET /api/v1/users/{userId}/images/{key}/{uploadId}/parts/{partNumber}\". Use this URL to upload
    individual parts and
     get an \"ETag\" for each part. To finish, call \"PUT
    /api/v1/users/{userId}/images/{key}/{uploadId}\"
     with the list of all uploaded parts, containing \"ETag\" and \"partNumber\" for each part. Part
    numbers start at 1.

    If \"multipart=false\", returns \"presignedUrl\" that is used to upload the image at once.

    Args:
        user_id (int):
        key (str):
        multipart (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        S3Upload
    """

    return sync_detailed(
        user_id=user_id,
        key=key,
        client=client,
        multipart=multipart,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    key: str,
    *,
    client: AuthenticatedClient | Client,
    multipart: bool | Unset = True,
) -> Response[S3Upload]:
    r"""Prepares an upload for an image

     If \"multipart=true\", returns \"uploadId\" that is used to fetch upload URLs for each part with
     \"GET /api/v1/users/{userId}/images/{key}/{uploadId}/parts/{partNumber}\". Use this URL to upload
    individual parts and
     get an \"ETag\" for each part. To finish, call \"PUT
    /api/v1/users/{userId}/images/{key}/{uploadId}\"
     with the list of all uploaded parts, containing \"ETag\" and \"partNumber\" for each part. Part
    numbers start at 1.

    If \"multipart=false\", returns \"presignedUrl\" that is used to upload the image at once.

    Args:
        user_id (int):
        key (str):
        multipart (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[S3Upload]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
        multipart=multipart,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    key: str,
    *,
    client: AuthenticatedClient | Client,
    multipart: bool | Unset = True,
) -> S3Upload | None:
    r"""Prepares an upload for an image

     If \"multipart=true\", returns \"uploadId\" that is used to fetch upload URLs for each part with
     \"GET /api/v1/users/{userId}/images/{key}/{uploadId}/parts/{partNumber}\". Use this URL to upload
    individual parts and
     get an \"ETag\" for each part. To finish, call \"PUT
    /api/v1/users/{userId}/images/{key}/{uploadId}\"
     with the list of all uploaded parts, containing \"ETag\" and \"partNumber\" for each part. Part
    numbers start at 1.

    If \"multipart=false\", returns \"presignedUrl\" that is used to upload the image at once.

    Args:
        user_id (int):
        key (str):
        multipart (bool | Unset):  Default: True.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        S3Upload
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            key=key,
            client=client,
            multipart=multipart,
        )
    ).parsed
