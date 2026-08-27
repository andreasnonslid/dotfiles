--- Shared harness for the specs in this directory.
---
--- Deliberately not mini.test / plenary / busted: those exist to test *plugins*
--- in a controlled child Neovim. What matters here is the opposite -- that this
--- config, loaded exactly as it is on a real machine, still holds its
--- invariants. So the specs run against the real init.lua and the harness stays
--- a few dozen lines with no dependency to keep in sync.
local M = {}

M.failures = {}
M.passes = 0

---@param name string what is being asserted, phrased so a failure reads as a report
---@param ok boolean
---@param detail? any shown only on failure -- the value that made it fail
function M.check(name, ok, detail)
  if ok then
    M.passes = M.passes + 1
    return
  end
  local line = name
  if detail ~= nil then
    line = line .. "\n        got: " .. (type(detail) == "string" and detail or vim.inspect(detail))
  end
  M.failures[#M.failures + 1] = line
end

--- Report and exit. Silent on success apart from one summary line: a test run
--- nobody reads must not print anything a human has to triage.
function M.finish()
  if #M.failures == 0 then
    io.stdout:write(("nvim: %d checks passed\n"):format(M.passes))
    vim.cmd("qa!")
    return
  end
  io.stdout:write(("nvim: %d passed, %d FAILED\n"):format(M.passes, #M.failures))
  for _, f in ipairs(M.failures) do
    io.stdout:write("  FAIL  " .. f .. "\n")
  end
  vim.cmd("cq!") -- non-zero exit
end

--- Block until cond() or timeout; returns whether it came true.
function M.wait_for(cond, timeout_ms)
  local deadline = vim.uv.now() + (timeout_ms or 10000)
  while vim.uv.now() < deadline do
    if cond() then
      return true
    end
    vim.wait(50)
  end
  return cond()
end

M.root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")

return M
