from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="S3Upload")


@_attrs_define
class S3Upload:
    """
    Attributes:
        upload_id (str | Unset):
        presigned_url (str | Unset):
    """

    upload_id: str | Unset = UNSET
    presigned_url: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        upload_id = self.upload_id

        presigned_url = self.presigned_url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if upload_id is not UNSET:
            field_dict["uploadId"] = upload_id
        if presigned_url is not UNSET:
            field_dict["presignedUrl"] = presigned_url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        upload_id = d.pop("uploadId", UNSET)

        presigned_url = d.pop("presignedUrl", UNSET)

        s3_upload = cls(
            upload_id=upload_id,
            presigned_url=presigned_url,
        )

        s3_upload.additional_properties = d
        return s3_upload

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
