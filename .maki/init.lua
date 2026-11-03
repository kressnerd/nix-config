-- givn:begin:timeline
local ok, reporter = pcall(require, "givn-timeline")
if ok and type(reporter) == "table" and reporter.setup then
  reporter.setup()
end
-- givn:end:timeline
