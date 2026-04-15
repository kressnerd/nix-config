from http import HTTPStatus
from typing import Any

import httpx

from ...client import AuthenticatedClient, Client
from ...types import Response
from ... import errors

from ...models.s3_sign_part_url import S3SignPartURL


def _get_kwargs(
    user_id: int,
    key: str,
    upload_id: str,
    part_number: int,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/api/v1/users/{user_id}/isos/{key}/{upload_id}/parts/{part_number}".format(
            user_id=user_id,
            key=key,
            upload_id=upload_id,
            part_number=part_number,
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> S3SignPartURL | None:
    if response.status_code == 200:
        response_200 = S3SignPartURL.from_dict(response.json())

        return response_200

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[S3SignPartURL]:
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
    part_number: int,
    *,
    client: AuthenticatedClient | Client,
) -> Response[S3SignPartURL]:
    r"""Get a presigned upload URL for a single part

     Call this endpoint for every part. Use the returned URL to upload the part and get an \"ETag\" from
    the HTTP headers in return.
    Once all parts are uploaded, call \"PUT /api/v1/users/{userId}/isos/{key}/{uploadId}\" with the list
    of all uploaded parts,
     containing \"ETag\" and \"partNumber\" for each part.

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        part_number (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[S3SignPartURL]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
        upload_id=upload_id,
        part_number=part_number,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    user_id: int,
    key: str,
    upload_id: str,
    part_number: int,
    *,
    client: AuthenticatedClient | Client,
) -> S3SignPartURL | None:
    r"""Get a presigned upload URL for a single part

     Call this endpoint for every part. Use the returned URL to upload the part and get an \"ETag\" from
    the HTTP headers in return.
    Once all parts are uploaded, call \"PUT /api/v1/users/{userId}/isos/{key}/{uploadId}\" with the list
    of all uploaded parts,
     containing \"ETag\" and \"partNumber\" for each part.

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        part_number (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        S3SignPartURL
    """

    return sync_detailed(
        user_id=user_id,
        key=key,
        upload_id=upload_id,
        part_number=part_number,
        client=client,
    ).parsed


async def asyncio_detailed(
    user_id: int,
    key: str,
    upload_id: str,
    part_number: int,
    *,
    client: AuthenticatedClient | Client,
) -> Response[S3SignPartURL]:
    r"""Get a presigned upload URL for a single part

     Call this endpoint for every part. Use the returned URL to upload the part and get an \"ETag\" from
    the HTTP headers in return.
    Once all parts are uploaded, call \"PUT /api/v1/users/{userId}/isos/{key}/{uploadId}\" with the list
    of all uploaded parts,
     containing \"ETag\" and \"partNumber\" for each part.

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        part_number (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[S3SignPartURL]
    """

    kwargs = _get_kwargs(
        user_id=user_id,
        key=key,
        upload_id=upload_id,
        part_number=part_number,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    user_id: int,
    key: str,
    upload_id: str,
    part_number: int,
    *,
    client: AuthenticatedClient | Client,
) -> S3SignPartURL | None:
    r"""Get a presigned upload URL for a single part

     Call this endpoint for every part. Use the returned URL to upload the part and get an \"ETag\" from
    the HTTP headers in return.
    Once all parts are uploaded, call \"PUT /api/v1/users/{userId}/isos/{key}/{uploadId}\" with the list
    of all uploaded parts,
     containing \"ETag\" and \"partNumber\" for each part.

    Args:
        user_id (int):
        key (str):
        upload_id (str):
        part_number (int):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        S3SignPartURL
    """

    return (
        await asyncio_detailed(
            user_id=user_id,
            key=key,
            upload_id=upload_id,
            part_number=part_number,
            client=client,
        )
    ).parsed
