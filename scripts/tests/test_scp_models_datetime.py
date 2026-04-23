"""Tests for null datetime handling in TaskInfo.from_dict().

Reproduces the crash when the SCP API returns null for finishedAt/startedAt.
RED PHASE: these tests are expected to FAIL until the bug is fixed.
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
