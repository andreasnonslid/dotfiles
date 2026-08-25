--- ctags index, gutentags-style but native: async regeneration via vim.system(),
--- tag files kept outside the repo under stdpath("cache")/tags/.
---
--- Scope follows config.workspaces: one tag file per workspace search dir, so
--- `<C-]>` reaches the extra dirs a workspace pulls in, not just cwd.
---
--- This complements LSP rather than competing with it. Neovim's lsp-defaults set
--- buffer-local 'tagfunc' to vim.lsp.tagfunc when a client attaches, so on an
--- LSP-backed buffer `<C-]>` resolves through the language server and never looks
--- at a tags file. The ctags index is what covers everything else: filetypes with
--- no server in lsp/*.lua, files outside the server's root, and the "just index
--- this pile of C" case. M.jump()/M.pick() below force the ctags path by
--- suspending 'tagfunc' for the duration of the jump.
local M = {}

local cache_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "tags")

--- Directories excluded from a non-git scan. Git roots use `git ls-files`
--- instead, which already honours .gitignore.
local EXCLUDE = {
  ".git",
  ".hg",
  ".svn",
  ".mypy_cache",
  ".pytest_cache",
  ".ruff_cache",
  ".tox",
  ".venv",
  "__pycache__",
  "build",
  "dist",
  "node_modules",
  "target",
  "venv",
}

--- Tag files larger than this are not parsed for the picker; `<C-]>` still works
--- (that lookup is binary-searched in C, this one is a Lua scan).
local PICKER_LINE_LIMIT = 200000

local DEBOUNCE_MS = 2000

---@type string|false|nil resolved ctags path, false once known unusable
local ctags_bin = nil
local ctags_warned = false

---@type table<string, boolean> roots with a regeneration in flight
local running = {}
---@type table<string, boolean> roots that changed while one was in flight
local queued = {}
---@type table<string, uv.uv_timer_t>
local timers = {}

local function normalize(dir)
  return (vim.fn.fnamemodify(dir, ":p"):gsub("/$", ""))
end

--- Cache-dir filename for a root. The basename keeps it recognisable when
--- poking around by hand; the hash keeps two same-named roots apart.
local function tagfile(root)
  local name = vim.fn.fnamemodify(root, ":t")
  if name == "" then
    name = "root"
  end
  return vim.fs.joinpath(cache_dir, ("%s-%s.tags"):format(name:gsub("[^%w._-]", "_"), vim.fn.sha256(root):sub(1, 8)))
end

local function roots()
  local ok, workspaces = pcall(require, "config.workspaces")
  if ok then
    return workspaces.search_dirs()
  end
  return { normalize(vim.fn.getcwd()) }
end

local function is_git_root(root)
  -- A worktree or submodule has .git as a file, not a directory.
  return vim.fn.isdirectory(vim.fs.joinpath(root, ".git")) == 1
    or vim.fn.filereadable(vim.fs.joinpath(root, ".git")) == 1
end

--- 'tags' is comma-separated; spaces and commas inside a path need escaping.
local function escape_tags_entry(path)
  return (path:gsub("[, ]", "\\%0"))
end

--- Point 'tags' at this workspace's tag files, keeping the built-in
--- "./tags;,tags" tail so a repo that ships its own tags file still works.
function M.refresh()
  local entries = {}
  for _, root in ipairs(roots()) do
    local file = tagfile(root)
    if vim.fn.filereadable(file) == 1 then
      entries[#entries + 1] = escape_tags_entry(file)
    end
  end
  entries[#entries + 1] = "./tags;"
  entries[#entries + 1] = "tags"
  vim.o.tags = table.concat(entries, ",")
end

--- Resolve ctags once. Universal Ctags only: Exuberant takes different flags and
--- silently produces a worse index, which is harder to debug than a refusal.
local function resolve_ctags()
  if ctags_bin ~= nil then
    return ctags_bin
  end
  local exe = vim.fn.exepath("ctags")
  if exe == "" then
    ctags_bin = false
    return false
  end
  local ok, res = pcall(function()
    return vim.system({ exe, "--version" }, { text = true }):wait(2000)
  end)
  if not ok or res.code ~= 0 or not (res.stdout or ""):match("Universal Ctags") then
    ctags_bin = false
    return false
  end
  ctags_bin = exe
  return exe
end

local function warn_missing_ctags()
  if ctags_warned then
    return
  end
  ctags_warned = true
  vim.notify(
    "tags: Universal Ctags not found on PATH — tag index disabled "
      .. "(apt install universal-ctags / brew install universal-ctags)",
    vim.log.levels.WARN
  )
end

local function finish(root, ok, err)
  running[root] = nil
  M.refresh()
  if not ok and err then
    vim.notify("tags: " .. err, vim.log.levels.ERROR)
  end
  if queued[root] then
    queued[root] = nil
    M.generate(root)
  end
end

--- Run ctags into a temp file, then rename over the real one, so a reader never
--- sees a half-written index.
---@param root string
---@param files string[]|nil absolute paths to index; nil means recurse from root
local function run_ctags(root, files)
  local bin = resolve_ctags()
  if not bin then
    warn_missing_ctags()
    finish(root, true)
    return
  end

  vim.fn.mkdir(cache_dir, "p")
  local out = tagfile(root)
  local tmp = out .. ".tmp"

  -- --tag-relative=never: the tag file lives in the cache dir, so paths recorded
  -- in it have to be absolute to resolve from anywhere.
  local cmd = { bin, "--tag-relative=never", "--fields=+n", "--languages=all", "-f", tmp }
  local opts = { text = true, cwd = root }

  if files then
    if #files == 0 then
      finish(root, true)
      return
    end
    vim.list_extend(cmd, { "-L", "-" })
    opts.stdin = table.concat(files, "\n") .. "\n"
  else
    for _, dir in ipairs(EXCLUDE) do
      cmd[#cmd + 1] = "--exclude=" .. dir
    end
    vim.list_extend(cmd, { "-R", root })
  end

  running[root] = true
  vim.system(cmd, opts, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        os.remove(tmp)
        finish(root, false, ("ctags exited %d for %s: %s"):format(res.code, root, vim.trim(res.stderr or "")))
        return
      end
      local ok, err = vim.uv.fs_rename(tmp, out)
      if not ok then
        os.remove(tmp)
        finish(root, false, ("could not install tag file for %s: %s"):format(root, tostring(err)))
        return
      end
      finish(root, true)
    end)
  end)
end

--- Regenerate the index for one root. Full rebuild rather than the per-file
--- incremental update gutentags does: with Universal Ctags a rebuild costs about
--- as much as rewriting the file, and it can't drift out of sync.
---@param root string
function M.generate(root)
  root = normalize(root)
  if root == "" or vim.fn.isdirectory(root) == 0 then
    return
  end
  if running[root] then
    queued[root] = true
    return
  end
  if not resolve_ctags() then
    warn_missing_ctags()
    return
  end

  if not is_git_root(root) then
    run_ctags(root, nil)
    return
  end

  running[root] = true
  vim.system({
    "git",
    "-C",
    root,
    "ls-files",
    "--cached",
    "--others",
    "--exclude-standard",
  }, { text = true }, function(res)
    vim.schedule(function()
      running[root] = nil
      if res.code ~= 0 then
        -- Not actually a usable git dir after all; fall back to a plain scan.
        run_ctags(root, nil)
        return
      end
      local files = {}
      for _, rel in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
        files[#files + 1] = vim.fs.joinpath(root, rel)
      end
      run_ctags(root, files)
    end)
  end)
end

--- Regenerate every workspace root.
function M.generate_all()
  for _, root in ipairs(roots()) do
    M.generate(root)
  end
end

--- Coalesce the burst of writes that a format-on-save or a :wall produces.
local function schedule_generate(root)
  root = normalize(root)
  local timer = timers[root]
  if timer then
    timer:stop()
  else
    timer = vim.uv.new_timer()
    timers[root] = timer
  end
  timer:start(
    DEBOUNCE_MS,
    0,
    vim.schedule_wrap(function()
      M.generate(root)
    end)
  )
end

local function root_for(path)
  path = normalize(path)
  local best, best_len = nil, 0
  for _, root in ipairs(roots()) do
    if path == root or path:find(root .. "/", 1, true) == 1 then
      if #root > best_len then
        best, best_len = root, #root
      end
    end
  end
  return best
end

--- Run fn with 'tagfunc' suspended, so tag commands consult the ctags index
--- instead of being answered by the language server.
---@param fn fun()
local function with_ctags(fn)
  local saved = vim.bo.tagfunc
  vim.bo.tagfunc = ""
  local ok, err = pcall(fn)
  vim.bo.tagfunc = saved
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

--- :tjump on a name, forced through the ctags index. Pushes the tag stack, so
--- `<C-t>` pops back out exactly as it does for a native `<C-]>`.
---@param name string|nil defaults to the word under the cursor
function M.jump(name)
  name = name or vim.fn.expand("<cword>")
  if name == "" then
    return
  end
  with_ctags(function()
    vim.cmd("tjump " .. vim.fn.escape(name, " \\|\"'"))
  end)
end

--- Parse the workspace tag files into one entry per tag name.
---@return {name: string, file: string, line: integer}[]
local function read_tags()
  local seen, items, total = {}, {}, 0
  for _, root in ipairs(roots()) do
    local file = tagfile(root)
    if vim.fn.filereadable(file) == 1 then
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok then
        for _, line in ipairs(lines) do
          total = total + 1
          if total > PICKER_LINE_LIMIT then
            return items
          end
          -- name<TAB>file<TAB>address;"<TAB>...<TAB>line:N
          if line:sub(1, 2) ~= "!_" then
            local name, path = line:match("^([^\t]+)\t([^\t]+)\t")
            if name and not seen[name] then
              seen[name] = true
              items[#items + 1] = {
                name = name,
                file = path,
                line = tonumber(line:match("\tline:(%d+)")) or 1,
              }
            end
          end
        end
      end
    end
  end
  return items
end

--- Pick a tag by name. Confirming runs :tjump, so an ambiguous name still gets
--- the native selection list and the tag stack still records the jump.
function M.pick()
  local entries = read_tags()
  if #entries == 0 then
    vim.notify("tags: no index yet — <leader>ct regenerates it", vim.log.levels.WARN)
    return
  end
  local items = vim.tbl_map(function(entry)
    return {
      text = entry.name,
      name = entry.name,
      file = entry.file,
      pos = { entry.line, 0 },
    }
  end, entries)

  require("snacks").picker.pick({
    title = "Tags",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.name then
        M.jump(item.name)
      end
    end,
  })
end

function M.setup()
  M.refresh()

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("config-tags", { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].buftype ~= "" then
        return
      end
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name == "" then
        return
      end
      local root = root_for(name)
      if root then
        schedule_generate(root)
      end
    end,
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    group = "config-tags",
    callback = function()
      M.refresh()
    end,
  })

  vim.api.nvim_create_user_command("TagsUpdate", function()
    M.generate_all()
    vim.notify("tags: regenerating " .. table.concat(roots(), ", "))
  end, { desc = "Regenerate the ctags index for every workspace dir" })

  vim.api.nvim_create_user_command("TagsInfo", function()
    local lines = {}
    for _, root in ipairs(roots()) do
      local file = tagfile(root)
      local stat = vim.uv.fs_stat(file)
      lines[#lines + 1] = ("%s\n  %s\n  %s"):format(
        root,
        file,
        stat and ("%.1f KiB, updated %s"):format(stat.size / 1024, os.date("%Y-%m-%d %H:%M", stat.mtime.sec))
          or "not generated"
      )
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Tags" })
  end, { desc = "Show the ctags index state for every workspace dir" })

  -- Native tag keys (<C-]>, <C-t>, g], g<C-]>, <C-w>], <C-w>}) are deliberately
  -- left alone; these only add what has no native key.
  vim.keymap.set("n", "<leader>ft", M.pick, { desc = "Find Tag" })
  vim.keymap.set("n", "<leader>fT", function()
    M.jump()
  end, { desc = "Jump to Tag under cursor (ctags, bypasses LSP)" })
  vim.keymap.set("n", "<leader>ct", "<cmd>TagsUpdate<CR>", { desc = "Regenerate Tags" })
end

return M
