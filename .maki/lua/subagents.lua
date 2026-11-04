-- Role subagents for Maki, projected from `.opencode/agent/*.md`.
--
-- The four role prompts are not copied here. The plugin reads the OpenCode role
-- file at call time and hands its markdown body to a Maki subagent session, so
-- editing `.opencode/agent/reviewer.md` changes Maki's reviewer and OpenCode's
-- reviewer in one step. What cannot cross that boundary is the frontmatter's
-- `permission:` map — it is OpenCode's schema, and Maki has no per-agent
-- override — so the tool filter below is a hand-translation of it. The mapping
-- is listed in `roles`, and `tests/unit/maki-subagent-roles-test.nix` fails if a
-- role file loses the frontmatter or the opening sentence this plugin relies on.
--
-- `coder` is deliberately absent: it is the implementation role, which Maki's
-- main session already is.
local M = {}

local AGENTS_DIR = ".opencode/agent"

local SHARED_PREAMBLE = [[

## Tools in this session

You run as a Maki subagent with a restricted tool set. Some tools named in this
prompt may be absent; if a tool you want is not available, say so and continue
with what you have. `code_execution` runs Python, so it cannot be used to reach
another tool. Return a written report or result to the caller — you cannot ask
the user a question, because no one can answer a permission prompt here.
]]

-- Per role: the file it is projected from, the paths it may write, and the
-- tools it must not have. A role with `write = {}` gets no edit-capable tool at
-- all, which is how "never modifies files" is enforced rather than merely stated.
local roles = {
  -- The architect keeps the write tools its OpenCode permission block grants
  -- (`docs/plans/**`), but no rule pre-approves them, and a role session has no
  -- one to answer a prompt, so in practice every write is refused. Planning is
  -- read-only here; the main session writes the plan.
  architect = {
    description = "Plans and designs an implementation. Never writes implementation code.",
    write = { "givn/changes/", "docs/plans/" },
    except = { "bash", "code_execution", "task", "webfetch", "websearch" },
  },
  researcher = {
    description = "Investigates codebase structure, technologies, and patterns. Never modifies files.",
    write = {},
    except = { "bash", "code_execution", "task", "webfetch", "websearch" },
  },
  reviewer = {
    description = "Reviews changed files, commits, or branches. Read-only.",
    write = {},
    except = { "bash", "code_execution", "task", "webfetch", "websearch" },
  },
  ["user-story-writer"] = {
    description = "Writes BDD user stories with Gherkin acceptance criteria.",
    write = { "docs/stories/" },
    except = { "bash", "code_execution", "task", "webfetch", "websearch" },
  },
}

-- Every tool that can change a file without going through `write`. A role that
-- may not write must lose all of them, or the restriction is cosmetic.
local WRITE_TOOLS = {
  write = true,
  edit = true,
  multiedit = true,
  edit_lines = true,
  bash = true,
  code_execution = true,
}

-- Tools that declare no capability, so handing one to a session costs every
-- permission and Maki refuses to open it. None is a read tool a role needs.
local UNBILLED = {
  view_image = true,
  batch = true,
  code_execution = true,
  task = true,
  question = true,
  todo_write = true,
  memory = true,
  task_stop = true,
  task_message = true,
  skill = true,
}

local function split_frontmatter(text)
  local body_start = text:find("\n---\n", 4, true)
  if text:sub(1, 4) ~= "---\n" or not body_start then
    return nil
  end
  return text:sub(body_start + 5)
end

local function read_body(role)
  local text = maki.fs.read(AGENTS_DIR .. "/" .. role .. ".md")
  if not text then
    return nil
  end
  local body = split_frontmatter(text)
  if not body then
    return nil, "no frontmatter block"
  end
  return body
end

-- The tool filter for a role, computed against what this session can call so a
-- tool Maki does not ship is not named in an exclusion.
local function exclusions(role, callable)
  local cfg = roles[role]
  local excluded = {}
  for _, name in ipairs(cfg.except) do
    excluded[name] = true
  end
  for name in pairs(UNBILLED) do
    excluded[name] = true
  end
  -- A role with no write path loses every tool that can change a file. This is
  -- the enforcement behind "never modifies files": the model is not offered the
  -- capability, rather than being denied it after it asks.
  if #cfg.write == 0 then
    for name in pairs(WRITE_TOOLS) do
      excluded[name] = true
    end
  end
  local list = {}
  for name in pairs(excluded) do
    if callable[name] then
      list[#list + 1] = name
    end
  end
  return list
end

function M.setup()
  maki.api.register_tool({
    name = "task_role",
    description = [[Run a role subagent and return its report.

- `architect` plans an implementation from a description of the change.
- `researcher` gathers codebase and documentation facts before a decision.
- `reviewer` reviews changed files for correctness and policy.
- `user-story-writer` turns requirements into BDD user stories.

Each role has a read-oriented tool set and its own system prompt; none can ask
the user a question, so give it everything it needs in `prompt`.]],
    kind = "agent",
    -- The session this tool opens holds the tools this plugin hands it, so the
    -- capability it declares is the one those tools reach. Without it Maki
    -- charges the tool every permission and refuses to open a session.
    permission = "run",
    schema = {
      type = "object",
      properties = {
        role = {
          type = "string",
          enum = { "architect", "researcher", "reviewer", "user-story-writer" },
          description = "Which role to run.",
        },
        prompt = {
          type = "string",
          description = "The full task for the role, including paths it should read.",
        },
      },
      required = { "role", "prompt" },
    },
    handler = function(input, ctx)
      local cfg = roles[input.role]
      if not cfg then
        return { output = "error: unknown role " .. tostring(input.role), is_error = true }
      end

      local body, err = read_body(input.role)
      if not body then
        return {
          output = "error: could not read " .. AGENTS_DIR .. "/" .. input.role .. ".md: " .. tostring(err),
          is_error = true,
        }
      end

      local callable = {}
      for _, t in ipairs(maki.agent.callable_tools(ctx) or {}) do
        callable[t.name] = true
      end

      local defs = maki.agent.tools(ctx, { audience = "general_sub", except = exclusions(input.role, callable) })
      if not defs then
        return { output = "error: could not build the tool set for " .. input.role, is_error = true }
      end

      local session, open_err = maki.agent.session(ctx, {
        system = body .. SHARED_PREAMBLE,
        tools = defs,
        name = input.role,
        thinking = "off",
      })
      if not session then
        return { output = "error: could not open the role session: " .. tostring(open_err), is_error = true }
      end

      -- `close` runs on every path, including an exception from `prompt`: a
      -- leaked role session stays visible as a task tab for the whole chat.
      local ok, result, prompt_err = pcall(session.prompt, session, input.prompt)
      session:close()
      if not ok then
        return { output = "error: " .. input.role .. " raised: " .. tostring(result), is_error = true }
      end
      if prompt_err and (type(result) ~= "table" or result.text == nil) then
        return { output = "error: " .. input.role .. ": " .. tostring(prompt_err), is_error = true }
      end
      -- A run cut short can hand back both an error and the text it streamed.
      local text = type(result) == "table" and result.text or nil
      if text == nil or text == "" then
        return { output = "(" .. input.role .. " returned no text)", is_error = prompt_err ~= nil }
      end
      return text
    end,
  })
end

return M
