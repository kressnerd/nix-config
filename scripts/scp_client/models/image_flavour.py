from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset


if TYPE_CHECKING:
    from ..models.image_minimal import ImageMinimal


T = TypeVar("T", bound="ImageFlavour")


@_attrs_define
class ImageFlavour:
    """
    Attributes:
        name (str):
        alias (str):
        text (str):
        id (int | Unset):
        image (ImageMinimal | Unset):
    """

    name: str
    alias: str
    text: str
    id: int | Unset = UNSET
    image: ImageMinimal | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        alias = self.alias

        text = self.text

        id = self.id

        image: dict[str, Any] | Unset = UNSET
        if not isinstance(self.image, Unset):
            image = self.image.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "alias": alias,
                "text": text,
            }
        )
        if id is not UNSET:
            field_dict["id"] = id
        if image is not UNSET:
            field_dict["image"] = image

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.image_minimal import ImageMinimal

        d = dict(src_dict)
        name = d.pop("name")

        alias = d.pop("alias")

        text = d.pop("text")

        id = d.pop("id", UNSET)

        _image = d.pop("image", UNSET)
        image: ImageMinimal | Unset
        if isinstance(_image, Unset) or _image is None:
            image = _image  # type: ignore[assignment]
        else:
            image = ImageMinimal.from_dict(_image)

        image_flavour = cls(
            name=name,
            alias=alias,
            text=text,
            id=id,
            image=image,
        )

        image_flavour.additional_properties = d
        return image_flavour

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
