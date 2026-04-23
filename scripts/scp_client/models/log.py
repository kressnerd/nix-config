from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.log_type import LogType
from dateutil.parser import isoparse
import datetime

if TYPE_CHECKING:
    from ..models.user_minimal import UserMinimal


T = TypeVar("T", bound="Log")


@_attrs_define
class Log:
    """
    Attributes:
        type_ (LogType | Unset):
        executing_user (UserMinimal | Unset):
        date (datetime.datetime | Unset):  Example: 2022-03-10T16:15:50Z.
        log_key (str | Unset):
        message (str | Unset):
    """

    type_: LogType | Unset = UNSET
    executing_user: UserMinimal | Unset = UNSET
    date: datetime.datetime | Unset = UNSET
    log_key: str | Unset = UNSET
    message: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_: str | Unset = UNSET
        if not isinstance(self.type_, Unset):
            type_ = self.type_.value

        executing_user: dict[str, Any] | Unset = UNSET
        if not isinstance(self.executing_user, Unset):
            executing_user = self.executing_user.to_dict()

        date: str | Unset = UNSET
        if not isinstance(self.date, Unset):
            date = self.date.isoformat()

        log_key = self.log_key

        message = self.message

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if type_ is not UNSET:
            field_dict["type"] = type_
        if executing_user is not UNSET:
            field_dict["executingUser"] = executing_user
        if date is not UNSET:
            field_dict["date"] = date
        if log_key is not UNSET:
            field_dict["logKey"] = log_key
        if message is not UNSET:
            field_dict["message"] = message

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.user_minimal import UserMinimal

        d = dict(src_dict)
        _type_ = d.pop("type", UNSET)
        type_: LogType | Unset
        if isinstance(_type_, Unset):
            type_ = UNSET
        else:
            type_ = LogType(_type_)

        _executing_user = d.pop("executingUser", UNSET)
        executing_user: UserMinimal | Unset
        if isinstance(_executing_user, Unset):
            executing_user = UNSET
        else:
            executing_user = UserMinimal.from_dict(_executing_user)

        _date = d.pop("date", UNSET)
        date: datetime.datetime | Unset
        if isinstance(_date, Unset) or _date is None:
            date = _date  # type: ignore[assignment]
        else:
            date = isoparse(_date)

        log_key = d.pop("logKey", UNSET)

        message = d.pop("message", UNSET)

        log = cls(
            type_=type_,
            executing_user=executing_user,
            date=date,
            log_key=log_key,
            message=message,
        )

        log.additional_properties = d
        return log

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
