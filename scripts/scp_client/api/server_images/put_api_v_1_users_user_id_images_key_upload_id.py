from http import HTTPStatus
from typing import Any, cast

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.s3_completed_part import S3CompletedPart
from ...models.s3_no_such_upload_error import S3NoSuchUploadError


def _get_kwargs(
    user_id: int,
    key: str,
    upload_id: str,
    *,
    body: list[S3CompletedPart],
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "put",
        "url": "/api/v1/users/{user_id}/images/{key}/{upload_id}".format(
            user_id=user_id,
            key=key,
            upload_id=upload_id,
        ),
    }

    _kwargs["json"] = []
    for body_item_data in body:
        body_item = body_item_data.to_dict()
        _kwargs["json"].append(body_item)

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Any | S3NoSuchUploadError | None:
    if response.status_code == 204:
        response_204 = cast(Any, None)
        return response_204

    if response.status_code == 404:
        response_404 = S3NoSuchUploadError.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Any | S3NoSuchUploadError]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    user_id: int,
    key: str,
    upload_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: list[S3CompletedPart],
) -> Response[Any | S3NoSuchUploadError]:
    r"""Completes a multipart upload for an image

     Call this endpoint after uploading all parts. The body must include a list of parts \"ETag\" and
    \"partNumber\" in order.
     This finishes the upload and makes the image available with the provided \"key\".

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        body (list[S3CompletedPart]):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | S3NoSuchUploadError]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
        upload_id=upload_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    key: str,
    upload_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: list[S3CompletedPart],
) -> Any | S3NoSuchUploadError | None:
    r"""Completes a multipart upload for an image

     Call this endpoint after uploading all parts. The body must include a list of parts \"ETag\" and
    \"partNumber\" in order.
     This finishes the upload and makes the image available with the provided \"key\".

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        body (list[S3CompletedPart]):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | S3NoSuchUploadError
    """

    return sync_detailed(
        user_id=user_id,
        key=key,
        upload_id=upload_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    key: str,
    upload_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: list[S3CompletedPart],
) -> Response[Any | S3NoSuchUploadError]:
    r"""Completes a multipart upload for an image

     Call this endpoint after uploading all parts. The body must include a list of parts \"ETag\" and
    \"partNumber\" in order.
     This finishes the upload and makes the image available with the provided \"key\".

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        body (list[S3CompletedPart]):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Any | S3NoSuchUploadError]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
        upload_id=upload_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    key: str,
    upload_id: str,
    *,
    client: AuthenticatedClient | Client,
    body: list[S3CompletedPart],
) -> Any | S3NoSuchUploadError | None:
    r"""Completes a multipart upload for an image

     Call this endpoint after uploading all parts. The body must include a list of parts \"ETag\" and
    \"partNumber\" in order.
     This finishes the upload and makes the image available with the provided \"key\".

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        body (list[S3CompletedPart]):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Any | S3NoSuchUploadError
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            key=key,
            upload_id=upload_id,
            client=client,
            body=body,
        )
    ).parsed
