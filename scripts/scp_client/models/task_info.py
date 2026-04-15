from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, TYPE_CHECKING

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

from ..models.task_state import TaskState
from dateutil.parser import isoparse
from typing import cast
import datetime

if TYPE_CHECKING:
    from ..models.task_progress import TaskProgress
    from ..models.user_minimal import UserMinimal
    from ..models.task_info_step import TaskInfoStep
    from ..models.task_info_result import TaskInfoResult
    from ..models.response_error import ResponseError


T = TypeVar("T", bound="TaskInfo")


@_attrs_define
class TaskInfo:
    """
    Attributes:
        uuid (str | Unset):
        name (str | Unset):
        state (TaskState | Unset):
        started_at (datetime.datetime | Unset):  Example: 2022-03-10T16:15:50Z.
        finished_at (datetime.datetime | Unset):  Example: 2022-03-10T16:15:50Z.
        executing_user (UserMinimal | Unset):
        task_progress (TaskProgress | Unset):
        message (None | str | Unset):
        on_rollback (bool | Unset):
        steps (list[TaskInfoStep] | Unset):
        result (TaskInfoResult | Unset):
        response_error (ResponseError | Unset):
    """

    uuid: str | Unset = UNSET
    name: str | Unset = UNSET
    state: TaskState | Unset = UNSET
    started_at: datetime.datetime | Unset = UNSET
    finished_at: datetime.datetime | Unset = UNSET
    executing_user: UserMinimal | Unset = UNSET
    task_progress: TaskProgress | Unset = UNSET
    message: None | str | Unset = UNSET
    on_rollback: bool | Unset = UNSET
    steps: list[TaskInfoStep] | Unset = UNSET
    result: TaskInfoResult | Unset = UNSET
    response_error: ResponseError | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        uuid = self.uuid

        name = self.name

        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        started_at: str | Unset = UNSET
        if not isinstance(self.started_at, Unset):
            started_at = self.started_at.isoformat()

        finished_at: str | Unset = UNSET
        if not isinstance(self.finished_at, Unset):
            finished_at = self.finished_at.isoformat()

        executing_user: dict[str, Any] | Unset = UNSET
        if not isinstance(self.executing_user, Unset):
            executing_user = self.executing_user.to_dict()

        task_progress: dict[str, Any] | Unset = UNSET
        if not isinstance(self.task_progress, Unset):
            task_progress = self.task_progress.to_dict()

        message: None | str | Unset
        if isinstance(self.message, Unset):
            message = UNSET
        else:
            message = self.message

        on_rollback = self.on_rollback

        steps: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.steps, Unset):
            steps = []
            for steps_item_data in self.steps:
                steps_item = steps_item_data.to_dict()
                steps.append(steps_item)

        result: dict[str, Any] | Unset = UNSET
        if not isinstance(self.result, Unset):
            result = self.result.to_dict()

        response_error: dict[str, Any] | Unset = UNSET
        if not isinstance(self.response_error, Unset):
            response_error = self.response_error.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if uuid is not UNSET:
            field_dict["uuid"] = uuid
        if name is not UNSET:
            field_dict["name"] = name
        if state is not UNSET:
            field_dict["state"] = state
        if started_at is not UNSET:
            field_dict["startedAt"] = started_at
        if finished_at is not UNSET:
            field_dict["finishedAt"] = finished_at
        if executing_user is not UNSET:
            field_dict["executingUser"] = executing_user
        if task_progress is not UNSET:
            field_dict["taskProgress"] = task_progress
        if message is not UNSET:
            field_dict["message"] = message
        if on_rollback is not UNSET:
            field_dict["onRollback"] = on_rollback
        if steps is not UNSET:
            field_dict["steps"] = steps
        if result is not UNSET:
            field_dict["result"] = result
        if response_error is not UNSET:
            field_dict["responseError"] = response_error

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.task_progress import TaskProgress
        from ..models.user_minimal import UserMinimal
        from ..models.task_info_step import TaskInfoStep
        from ..models.task_info_result import TaskInfoResult
        from ..models.response_error import ResponseError

        d = dict(src_dict)
        uuid = d.pop("uuid", UNSET)

        name = d.pop("name", UNSET)

        _state = d.pop("state", UNSET)
        state: TaskState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = TaskState(_state)

        _started_at = d.pop("startedAt", UNSET)
        started_at: datetime.datetime | Unset
        if isinstance(_started_at, Unset):
            started_at = UNSET
        else:
            started_at = isoparse(_started_at)

        _finished_at = d.pop("finishedAt", UNSET)
        finished_at: datetime.datetime | Unset
        if isinstance(_finished_at, Unset):
            finished_at = UNSET
        else:
            finished_at = isoparse(_finished_at)

        _executing_user = d.pop("executingUser", UNSET)
        executing_user: UserMinimal | Unset
        if isinstance(_executing_user, Unset):
            executing_user = UNSET
        else:
            executing_user = UserMinimal.from_dict(_executing_user)

        _task_progress = d.pop("taskProgress", UNSET)
        task_progress: TaskProgress | Unset
        if isinstance(_task_progress, Unset):
            task_progress = UNSET
        else:
            task_progress = TaskProgress.from_dict(_task_progress)

        def _parse_message(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        message = _parse_message(d.pop("message", UNSET))

        on_rollback = d.pop("onRollback", UNSET)

        _steps = d.pop("steps", UNSET)
        steps: list[TaskInfoStep] | Unset = UNSET
        if _steps is not UNSET:
            steps = []
            for steps_item_data in _steps:
                steps_item = TaskInfoStep.from_dict(steps_item_data)

                steps.append(steps_item)

        _result = d.pop("result", UNSET)
        result: TaskInfoResult | Unset
        if isinstance(_result, Unset):
            result = UNSET
        else:
            result = TaskInfoResult.from_dict(_result)

        _response_error = d.pop("responseError", UNSET)
        response_error: ResponseError | Unset
        if isinstance(_response_error, Unset):
            response_error = UNSET
        else:
            response_error = ResponseError.from_dict(_response_error)

        task_info = cls(
            uuid=uuid,
            name=name,
            state=state,
            started_at=started_at,
            finished_at=finished_at,
            executing_user=executing_user,
            task_progress=task_progress,
            message=message,
            on_rollback=on_rollback,
            steps=steps,
            result=result,
            response_error=response_error,
        )

        task_info.additional_properties = d
        return task_info

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
