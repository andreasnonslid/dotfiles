-- The lockfile is the reason this config reproduces across machines. A plugin
-- added to the spec but missing from the lockfile is a plugin that will resolve
-- to a different commit on the next machine that clones this repo.
local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local t = dofile(here .. "/init.lua")

require("lazy").install({ show = false, wait = true })

local lockfile = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
t.check("lazy-lock.json exists", vim.fn.filereadable(lockfile) == 1, lockfile)

if vim.fn.filereadable(lockfile) == 1 then
  local ok, locked = pcall(vim.json.decode, table.concat(vim.fn.readfile(lockfile), "\n"))
  t.check("lazy-lock.json parses", ok and type(locked) == "table")
  if ok then
    for name in pairs(require("lazy.core.config").plugins) do
      t.check(("%s is pinned in lazy-lock.json"):format(name), locked[name] ~= nil)
      if locked[name] then
        t.check(
          ("%s pin is a full commit sha"):format(name),
          type(locked[name].commit) == "string" and #locked[name].commit == 40,
          locked[name].commit
        )
      end
    end
  end
end

t.finish()
