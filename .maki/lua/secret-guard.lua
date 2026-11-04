-- Secret-access guard for Maki, the counterpart of
-- `.omp/hooks/pre/secret-access-guard.js`.
--
-- `M.rules` is plain data so the rule shape can be checked without a Lua VM
-- (`tests/unit/maki-secret-guard.mjs`), and it is written out literally rather
-- than built in a loop so it can be reviewed by reading the file. `M.setup` is
-- the only code that touches Maki. A deny needs no plugin permission, so
-- `.maki/plugin.toml` is unchanged.
--
-- Two surfaces are covered and one is not, and the missing one is deliberate:
--
--   * `bash` — a deny is anchored at the start of the command and is also
--     checked against each shell segment, so `sops *` catches
--     `cd /tmp && sops -d f`. Only the commands named below are denied.
--     Independently, Maki refuses any bash call that would prompt when nothing
--     can answer it, so under `maki --print` and in a task-scoped session the
--     whole shell is closed regardless of these rules; in an interactive chat a
--     command that no rule names is left to the user's approval.
--   * `write`/`edit` — the protected subtrees cannot be modified.
--   * `read`/`grep` — **not covered.** Maki's read and grep handlers are
--     session-owned Lua tools (`lua:read` in the log), and a rule registered
--     here for either tool is accepted and then never fires. Shipping one would
--     claim protection that does not exist. Recorded as R-036.
local M = {}

-- Decryption commands, anchored at the start of the command. A bash scope is also
-- checked against each shell segment, so `cd /tmp && sops -d f` still matches
-- `sops *`. A scope that begins with a wildcard (`*sops *`) is accepted by
-- `register_permission_rule` and then matches nothing — verified by probe — so
-- every rule below is anchored. Reading a secret store with an unanticipated
-- command (`cat`, `grep`, `head`, …) is not covered by a rule; that surface is
-- closed only when Maki refuses the prompt, which it does under `--print` and in
-- a task-scoped session, and left open in an interactive chat where the user can
-- approve it — or where a `.maki/permissions.toml` bash `allow` list names the
-- command. See R-036.
M.rules = {
  -- Decryption tools, in every invocation form.
  { tool = "bash", scope = "sops *", effect = "deny" },
  { tool = "bash", scope = "ssh-to-age *", effect = "deny" },
  { tool = "bash", scope = "age -d*", effect = "deny" },
  { tool = "bash", scope = "age --decrypt*", effect = "deny" },

  -- Path scopes, so modification is refused even when a command slips past the
  -- shell rules. These are the trees that hold plaintext on this host.
  { tool = "write", scope = "/run/secrets/**", effect = "deny" },
  { tool = "edit", scope = "/run/secrets/**", effect = "deny" },
  { tool = "write", scope = "/home/dan/.config/sops-nix/secrets/**", effect = "deny" },
  { tool = "edit", scope = "/home/dan/.config/sops-nix/secrets/**", effect = "deny" },
  { tool = "write", scope = "/var/lib/sops-nix/**", effect = "deny" },
  { tool = "edit", scope = "/var/lib/sops-nix/**", effect = "deny" },
  { tool = "write", scope = "/home/dan/.config/sops/age/**", effect = "deny" },
  { tool = "edit", scope = "/home/dan/.config/sops/age/**", effect = "deny" },

  -- Deliberately absent: read and grep. See the header and R-036.
}

function M.setup()
  for _, rule in ipairs(M.rules) do
    local ok, err = pcall(maki.api.register_permission_rule, rule)
    if not ok then
      maki.log.warn("secret-guard: rule " .. rule.tool .. " " .. rule.scope .. " refused: " .. tostring(err))
    end
  end
end

return M
