from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


T = TypeVar("T", bound="S3NoSuchUploadError")


@_attrs_define
class S3NoSuchUploadError:
    """
    Example:
        {'message': 'Upload of example.img with uploadId
            ODJmZWRkZGYtOTNlNC00MjE4LWFjYmItZmZiMmFkODdmOTE2LjJmMDRhZTk5LTg3MGMtNDhkZi04ZjE4LWM4OGYxOTlmMTQ5Ng== not
            found.'}

    Attributes:
        code (str | Unset):
        message (str | Unset):
    """

    code: str | Unset = UNSET
    message: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        code = self.code

        message = self.message

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if code is not UNSET:
            field_dict["code"] = code
        if message is not UNSET:
            field_dict["message"] = message

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        code = d.pop("code", UNSET)

        message = d.pop("message", UNSET)

        s3_no_such_upload_error = cls(
            code=code,
            message=message,
        )

        s3_no_such_upload_error.additional_properties = d
        return s3_no_such_upload_error

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
