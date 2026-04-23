"""Tests for null datetime and null nested object handling in TaskInfo.from_dict().

Reproduces crashes when the SCP API returns null for finishedAt/startedAt and
for nested object fields like responseError, executingUser, taskProgress, result,
and list fields like steps.
RED PHASE: these tests are expected to FAIL until the bugs are fixed.
"""

from __future__ import annotations

import datetime

import pytest

from scp_client.models.task_info import TaskInfo


_MINIMAL_TASK: dict[str, object] = {
    "uuid": "test-uuid-1234",
    "name": "test-task",
    "state": "FINISHED",
}


class TestTaskInfoNullDatetimes:
    def test_task_info_from_dict_null_finished_at(self) -> None:
        """TaskInfo.from_dict() must not raise when finishedAt is null."""
        data = {**_MINIMAL_TASK, "finishedAt": None}
        result = TaskInfo.from_dict(data)
        assert result.finished_at is None

    def test_task_info_from_dict_null_started_at(self) -> None:
        """TaskInfo.from_dict() must not raise when startedAt is null."""
        data = {**_MINIMAL_TASK, "startedAt": None}
        result = TaskInfo.from_dict(data)
        assert result.started_at is None

    def test_task_info_from_dict_valid_datetime(self) -> None:
        """TaskInfo.from_dict() parses a valid ISO datetime string into datetime."""
        data = {**_MINIMAL_TASK, "finishedAt": "2022-03-10T16:15:50Z"}
        result = TaskInfo.from_dict(data)
        assert isinstance(result.finished_at, datetime.datetime)


def _make_task_info_dict() -> dict[str, object]:
    """Return a minimal valid TaskInfo dict."""
    return {
        "uuid": "test-uuid-1234",
        "name": "test-task",
        "state": "FINISHED",
    }


class TestTaskInfoNullNestedObjects:
    def test_task_info_from_dict_null_response_error(self) -> None:
        """TaskInfo.from_dict() must not raise when responseError is null."""
        data = _make_task_info_dict()
        data["responseError"] = None
        result = TaskInfo.from_dict(data)
        assert result.response_error is None

    def test_task_info_from_dict_null_executing_user(self) -> None:
        """TaskInfo.from_dict() must not raise when executingUser is null."""
        data = _make_task_info_dict()
        data["executingUser"] = None
        result = TaskInfo.from_dict(data)
        assert result.executing_user is None

    def test_task_info_from_dict_null_task_progress(self) -> None:
        """TaskInfo.from_dict() must not raise when taskProgress is null."""
        data = _make_task_info_dict()
        data["taskProgress"] = None
        result = TaskInfo.from_dict(data)
        assert result.task_progress is None

    def test_task_info_from_dict_null_result_field(self) -> None:
        """TaskInfo.from_dict() must not raise when result is null."""
        data = _make_task_info_dict()
        data["result"] = None
        result = TaskInfo.from_dict(data)
        assert result.result is None

    def test_task_info_from_dict_null_steps(self) -> None:
        """TaskInfo.from_dict() must not raise when steps is null."""
        data = _make_task_info_dict()
        data["steps"] = None
        result = TaskInfo.from_dict(data)
        assert result.steps is None
