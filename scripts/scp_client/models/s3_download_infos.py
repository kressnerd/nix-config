from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.s3_download_infos_headers import S3DownloadInfosHeaders


T = TypeVar("T", bound="S3DownloadInfos")


@_attrs_define
class S3DownloadInfos:
    """
    Attributes:
        filename (str | Unset):
        presigned_url (str | Unset):
        presigned_url_validity_duration_in_hours (int | Unset):
        headers (S3DownloadInfosHeaders | Unset):
    """

    filename: str | Unset = UNSET
    presigned_url: str | Unset = UNSET
    presigned_url_validity_duration_in_hours: int | Unset = UNSET
    headers: S3DownloadInfosHeaders | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        filename = self.filename

        presigned_url = self.presigned_url

        presigned_url_validity_duration_in_hours = (
            self.presigned_url_validity_duration_in_hours
        )

        headers: dict[str, Any] | Unset = UNSET
        if not isinstance(self.headers, Unset):
            headers = self.headers.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if filename is not UNSET:
            field_dict["filename"] = filename
        if presigned_url is not UNSET:
            field_dict["presignedUrl"] = presigned_url
        if presigned_url_validity_duration_in_hours is not UNSET:
            field_dict["presignedUrlValidityDurationInHours"] = (
                presigned_url_validity_duration_in_hours
            )
        if headers is not UNSET:
            field_dict["headers"] = headers

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.s3_download_infos_headers import S3DownloadInfosHeaders

        d = dict(src_dict)
        filename = d.pop("filename", UNSET)

        presigned_url = d.pop("presignedUrl", UNSET)

        presigned_url_validity_duration_in_hours = d.pop(
            "presignedUrlValidityDurationInHours", UNSET
        )

        _headers = d.pop("headers", UNSET)
        headers: S3DownloadInfosHeaders | Unset
        if isinstance(_headers, Unset) or _headers is None:
            headers = _headers  # type: ignore[assignment]
        else:
            headers = S3DownloadInfosHeaders.from_dict(_headers)

        s3_download_infos = cls(
            filename=filename,
            presigned_url=presigned_url,
            presigned_url_validity_duration_in_hours=presigned_url_validity_duration_in_hours,
            headers=headers,
        )

        s3_download_infos.additional_properties = d
        return s3_download_infos

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
