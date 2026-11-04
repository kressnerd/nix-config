-- givn:begin:timeline
local ok, reporter = pcall(require, "givn-timeline")
if ok and type(reporter) == "table" and reporter.setup then
  reporter.setup()
end
-- givn:end:timeline

-- givn:begin:secret-guard
local guardOk, guard = pcall(require, "secret-guard")
if guardOk and type(guard) == "table" and guard.setup then
  guard.setup()
end
-- givn:end:secret-guard

-- givn:begin:subagents
local rolesOk, roles = pcall(require, "subagents")
if rolesOk and type(roles) == "table" and roles.setup then
  roles.setup()
end
-- givn:end:subagents
