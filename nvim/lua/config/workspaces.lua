--- Multi-root workspace: one LSP/compile root + extra picker search dirs.
local M = {}

local state_file = vim.fn.stdpath("state") .. "/workspaces.json"
local MAX_RECENT = 30

---@class WorkspaceEntry
---@field root string LSP / compile_commands root (nvim cwd when active)
---@field dirs string[] root + extra search paths for snacks picker
---@field name? string
---@field last_used number unix time

---@type table<string, WorkspaceEntry>
local entries = {}
---@type string[]
local recent = {}
---@type string?
local active_root

local function normalize(dir)
  return vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
end

local function uniq_dirs(dirs)
  local seen = {}
  local out = {}
  for _, d in ipairs(dirs) do
    d = normalize(d)
    if d ~= "" and not seen[d] then
      seen[d] = true
      out[#out + 1] = d
    end
  end
  return out
end

local function touch(root)
  root = normalize(root)
  local now = os.time()
  if entries[root] then
    entries[root].last_used = now
  end
  recent = vim.tbl_filter(function(r)
    return r ~= root
  end, recent)
  table.insert(recent, 1, root)
  if #recent > MAX_RECENT then
    table.remove(recent)
  end
end

local function save()
  vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
  local f = assert(io.open(state_file, "w"))
  f:write(vim.json.encode({
    version = 2,
    entries = entries,
    recent = recent,
    active_root = active_root,
  }))
  f:close()
end

local function migrate_v1(data)
  if type(data) ~= "table" then
    return
  end
  for k, v in pairs(data) do
    if type(k) == "string" and k:sub(1, 1) == "/" and type(v) == "table" and v.dirs then
      local root = normalize(k)
      local dirs = uniq_dirs(v.dirs)
      if #dirs == 0 then
        dirs = { root }
      elseif dirs[1] ~= root then
        table.insert(dirs, 1, root)
        dirs = uniq_dirs(dirs)
      end
      entries[root] = {
        root = root,
        dirs = dirs,
        last_used = v.last_used or 0,
        name = v.name,
      }
    end
  end
end

local function load()
  local f = io.open(state_file, "r")
  if not f then
    return
  end
  local content = f:read("*a")
  f:close()
  if content == "" then
    return
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return
  end
  if data.version == 2 then
    entries = data.entries or {}
    recent = data.recent or {}
    active_root = data.active_root
  else
    migrate_v1(data)
  end
end

---@param root string
---@return WorkspaceEntry
local function ensure_entry(root)
  root = normalize(root)
  local ws = entries[root]
  if not ws then
    ws = { root = root, dirs = { root }, last_used = os.time() }
    entries[root] = ws
  elseif ws.dirs[1] ~= root then
    ws.dirs = uniq_dirs(vim.list_extend({ root }, ws.dirs))
  end
  return ws
end

function M.find_root_for_path(path)
  path = normalize(path)
  local best ---@type string?
  local best_len = 0
  for root in pairs(entries) do
    if path == root or path:find(root .. "/", 1, true) == 1 then
      if #root > best_len then
        best = root
        best_len = #root
      end
    end
  end
  return best
end

function M.root()
  return active_root or normalize(vim.fn.getcwd())
end

function M.current()
  return entries[M.root()]
end

function M.search_dirs()
  local ws = M.current()
  if ws and ws.dirs and #ws.dirs > 0 then
    return ws.dirs
  end
  return { M.root() }
end

--- Extra opts for snacks picker: multi-dir search, cwd stays at workspace root.
function M.picker_opts(extra)
  local dirs = M.search_dirs()
  local opts = {
    cwd = M.root(),
    dirs = #dirs > 1 and dirs or nil,
    root = false,
  }
  if extra then
    opts = vim.tbl_deep_extend("force", opts, extra)
  end
  return opts
end

function M.label(ws)
  local name = ws.name or vim.fn.fnamemodify(ws.root, ":t")
  local extra = #ws.dirs - 1
  if extra > 0 then
    return string.format("%s  (+%d dirs) — %s", name, extra, ws.root)
  end
  return string.format("%s — %s", name, ws.root)
end

function M.list_recent()
  local list = {}
  local seen = {}
  for _, root in ipairs(recent) do
    if entries[root] and not seen[root] then
      seen[root] = true
      list[#list + 1] = entries[root]
    end
  end
  for root, ws in pairs(entries) do
    if not seen[root] then
      list[#list + 1] = ws
    end
  end
  table.sort(list, function(a, b)
    return (a.last_used or 0) > (b.last_used or 0)
  end)
  return list
end

---@param root string
---@param opts? {silent?: boolean, create?: boolean}
function M.activate(root, opts)
  opts = opts or {}
  root = normalize(root)
  if not entries[root] then
    if not opts.create then
      vim.notify("Unknown workspace: " .. root, vim.log.levels.WARN)
      return
    end
    ensure_entry(root)
  end
  active_root = root
  touch(root)
  save()
  if vim.fn.getcwd() ~= root then
    vim.cmd.cd(vim.fn.fnameescape(root))
  end
  if not opts.silent then
    vim.notify("Workspace: " .. M.label(entries[root]), vim.log.levels.INFO)
  end
end

function M.sync_cwd()
  local cwd = normalize(vim.fn.getcwd())
  local found = M.find_root_for_path(cwd)
  if found then
    M.activate(found, { silent = true })
    return
  end
  ensure_entry(cwd)
  M.activate(cwd, { silent = true, create = true })
end

function M.create_for_cwd()
  local root = normalize(vim.fn.getcwd())
  if entries[root] then
    vim.notify("Workspace already exists: " .. root, vim.log.levels.INFO)
    M.activate(root)
    return
  end
  ensure_entry(root)
  M.activate(root)
end

function M.add_dir(dir)
  local root = M.root()
  local ws = ensure_entry(root)
  if not dir or dir == "" then
    return
  end
  dir = normalize(dir)
  for _, d in ipairs(ws.dirs) do
    if d == dir then
      vim.notify("Already in workspace search dirs: " .. dir, vim.log.levels.INFO)
      return
    end
  end
  table.insert(ws.dirs, dir)
  ws.dirs = uniq_dirs(ws.dirs)
  touch(root)
  save()
  vim.notify("Added search dir: " .. dir)
end

function M.open_picker()
  local snacks = require("snacks")
  local items = vim.tbl_map(function(ws)
    return {
      text = M.label(ws),
      file = ws.root,
      root = ws.root,
    }
  end, M.list_recent())

  if #items == 0 then
    vim.notify("No saved workspaces — create one with <leader>Wn", vim.log.levels.WARN)
    return
  end

  snacks.picker.pick({
    title = "Workspaces",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.root then
        M.activate(item.root)
      end
    end,
  })
end

function M.edit()
  local root = M.root()
  local ws = ensure_entry(root)

  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "# Workspace root (LSP / compile_commands) — first path below:",
    ws.root,
    "# Extra search dirs (one per line; root is always included):",
  }
  for _, d in ipairs(ws.dirs) do
    if d ~= ws.root then
      table.insert(lines, d)
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "workspace"
  vim.api.nvim_buf_set_name(buf, "workspace://" .. root)

  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local height = math.min(24, math.floor(vim.o.lines * 0.6))
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Workspace ",
    title_pos = "center",
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local paths = {}
      for _, line in ipairs(current) do
        line = vim.trim(line)
        if line ~= "" and not line:match("^#") then
          paths[#paths + 1] = normalize(line)
        end
      end
      if #paths == 0 then
        vim.notify("Workspace needs a root path", vim.log.levels.ERROR)
        return
      end
      local new_root = paths[1]
      local new_dirs = uniq_dirs(paths)
      if entries[root] and new_root ~= root then
        entries[root] = nil
      end
      entries[new_root] = {
        root = new_root,
        dirs = new_dirs,
        name = ws.name,
        last_used = os.time(),
      }
      active_root = new_root
      touch(new_root)
      save()
      vim.bo[buf].modified = false
      vim.notify("Workspace saved (" .. #new_dirs .. " dirs, root: " .. new_root .. ")")
    end,
  })

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close" })
end

function M.setup()
  load()
  M.sync_cwd()

  vim.api.nvim_create_user_command("WorkspaceOpen", M.open_picker, { desc = "Open saved workspace" })
  vim.api.nvim_create_user_command("WorkspaceCreate", M.create_for_cwd, {
    desc = "Create/switch workspace for cwd as root",
  })
  vim.api.nvim_create_user_command("WorkspaceEdit", M.edit, {
    desc = "Edit workspace root and search dirs",
  })
  vim.api.nvim_create_user_command("WorkspaceAdd", function(opts)
    M.add_dir(opts.args ~= "" and opts.args or vim.fn.getcwd())
  end, { nargs = "?", complete = "dir", desc = "Add search dir to workspace" })

  vim.keymap.set("n", "<leader>Wo", M.open_picker, { desc = "Workspace: Open" })
  vim.keymap.set("n", "<leader>Wn", M.create_for_cwd, { desc = "Workspace: New (cwd as root)" })
  vim.keymap.set("n", "<leader>We", M.edit, { desc = "Workspace: Edit dirs" })
  vim.keymap.set("n", "<leader>Wa", function()
    M.add_dir(vim.fn.getcwd())
  end, { desc = "Workspace: Add cwd to search" })
end

return M
