-- config.tags, driven against a stubbed Universal Ctags (fixtures/fake-ctags)
-- so the spec runs on a machine with no ctags installed and always produces the
-- same index. Fixture paths come from run.sh.
local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
local t = dofile(here .. "/init.lua")

local gitproj = assert(os.getenv("NVIM_TEST_GITPROJ"), "run via tests/run.sh")
local plaindir = assert(os.getenv("NVIM_TEST_PLAINDIR"), "run via tests/run.sh")

require("lazy").install({ show = false, wait = true })

-- Scope the index at both fixtures, standing in for a workspace with an extra dir.
package.loaded["config.workspaces"].search_dirs = function()
  return { gitproj, plaindir }
end

local tags = require("config.tags")
tags.generate_all()

local cache = vim.fs.joinpath(vim.fn.stdpath("cache"), "tags")
local function tagfiles()
  return vim.fn.glob(vim.fs.joinpath(cache, "*.tags"), false, true)
end
t.check(
  "an index is written per workspace dir",
  t.wait_for(function()
    return #tagfiles() == 2
  end, 20000),
  tagfiles()
)
t.check("no temp file survives a successful run", #vim.fn.glob(vim.fs.joinpath(cache, "*.tmp"), false, true) == 0)

local blob = {}
for _, f in ipairs(tagfiles()) do
  vim.list_extend(blob, vim.fn.readfile(f))
end
blob = table.concat(blob, "\n")
t.check("git root indexed a tracked file", blob:find("sym_a_c", 1, true) ~= nil)
t.check("git root indexed a nested file", blob:find("sym_b_c", 1, true) ~= nil)
t.check("gitignored file stayed out of the index", blob:find("junk_log", 1, true) == nil)
t.check("non-git root fell back to a recursive scan", blob:find("recursed_c_c", 1, true) ~= nil)

tags.refresh()
t.check("'tags' lists both indexes", select(2, vim.o.tags:gsub("%.tags", "")) == 2, vim.o.tags)
t.check("'tags' keeps the builtin tail", vim.o.tags:find("./tags;", 1, true) ~= nil, vim.o.tags)
t.check("has_index() sees the index", tags.has_index() == true)

vim.cmd.edit(vim.fs.joinpath(gitproj, "a.c"))
t.check("a generated tag resolves through taglist", #vim.fn.taglist("^sym_a_c$") == 1)
t.check("Snacks supplies the tag picker", type(require("snacks").picker.tags) == "function")

-- The regression that shipped once: 'tagfunc' is buffer-local and a successful
-- jump lands in a different buffer, so the restore has to name its own buffer.
vim.cmd.edit(vim.fs.joinpath(gitproj, "sub", "b.c"))
local origin = vim.api.nvim_get_current_buf()
vim.bo[origin].tagfunc = "v:lua.vim.lsp.tagfunc"
tags.jump("sym_a_c")
local landed = vim.api.nvim_get_current_buf()
t.check("jump crossed into another buffer", landed ~= origin, vim.api.nvim_buf_get_name(0))
t.check("origin buffer kept its tagfunc", vim.bo[origin].tagfunc == "v:lua.vim.lsp.tagfunc", vim.bo[origin].tagfunc)
t.check("destination buffer was not given origin's tagfunc", vim.bo[landed].tagfunc == "", vim.bo[landed].tagfunc)
t.check("the jump pushed the tag stack, so <C-t> returns", vim.fn.gettagstack().length >= 1)

-- Regeneration is debounced, not synchronous: a write must not stall on ctags.
local proj_index
for _, f in ipairs(tagfiles()) do
  if f:find(vim.fn.fnamemodify(gitproj, ":t"), 1, true) then
    proj_index = f
  end
end
if proj_index then
  os.remove(proj_index)
  vim.cmd.edit(vim.fs.joinpath(gitproj, "a.c"))
  vim.cmd("silent write")
  t.check("a write does not regenerate synchronously", vim.fn.filereadable(proj_index) == 0)
  t.check(
    "the debounced regeneration lands",
    t.wait_for(function()
      return vim.fn.filereadable(proj_index) == 1
    end, 20000)
  )
end

t.finish()
