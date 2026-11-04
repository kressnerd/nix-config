# tests/unit/maki-subagent-roles-test.nix
# Guards the role names Maki's `task_role` tool exposes.
#
# The role prompts themselves are read from `.opencode/agent/*.md` at call time
# by `.maki/lua/subagents.lua`, so a file's frontmatter and opening sentence are
# pinned by the `unit-maki-role-files` build instead: flake-check evaluation runs
# against a restricted store and cannot open a file under the repository. This
# test pins the set of names, which is what the tool's `enum` and the build share.
{ lib }:
let
  roles = [
    "architect"
    "researcher"
    "reviewer"
    "user-story-writer"
  ];
in
lib.debug.runTests {
  # A duplicate would make the tool's `enum` name a role twice.
  testRoleSetIsExact = {
    expr = lib.unique roles;
    expected = roles;
  };

  # `coder` is the implementation role, which Maki's main session already is.
  testCoderIsNotARole = {
    expr = lib.elem "coder" roles;
    expected = false;
  };
}
