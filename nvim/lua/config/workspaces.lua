--- Title-keyed workspaces. User file is JSON; meta (active/last_used) stays separate.
local M = {}

local state_dir = vim.fn.stdpath("state")
local user_file = state_dir .. "/workspaces.json"
local meta_file = state_dir .. "/workspaces-meta.json"

---@class WorkspaceEntry
---@field title string
---@field root string
---@field dirs string[]

---@type table<string, WorkspaceEntry> keyed by title
local entries = {}
---@type string?
local active_title
---@type table<string, number>
local last_used = {}

local function normalize(dir)
  return vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
end

local function uniq_dirs(dirs)
  local seen, out = {}, {}
  for _, d in ipairs(dirs) do
    d = normalize(d)
    if d ~= "" and not seen[d] then
      seen[d] = true
      out[#out + 1] = d
    end
  end
  return out
end

local function default_title(root)
  local name = vim.fn.fnamemodify(root, ":t")
  if name == "" then
    return "workspace"
  end
  return name
end

local function unique_title(base)
  if not entries[base] then
    return base
  end
  local n = 2
  while entries[base .. "-" .. n] do
    n = n + 1
  end
  return base .. "-" .. n
end

--- Extra dirs only (root is implicit). Empty array keeps a JSONC hint comment.
local function encode_user()
  local titles = vim.tbl_keys(entries)
  table.sort(titles)
  if #titles == 0 then
    return "{\n}\n"
  end
  local chunks = { "{\n" }
  for i, title in ipairs(titles) do
    local ws = entries[title]
    local dir_block
    if #ws.dirs == 0 then
      dir_block = "[\n      // extra search/LSP dirs, e.g. \"/abs/path/to/lib\"\n    ]"
    else
      local dirs = {}
      for _, d in ipairs(ws.dirs) do
        dirs[#dirs + 1] = "      " .. vim.json.encode(d)
      end
      dir_block = "[\n" .. table.concat(dirs, ",\n") .. "\n    ]"
    end
    local comma = i < #titles and "," or ""
    chunks[#chunks + 1] = ("  %s: {\n    \"root\": %s,\n    \"dirs\": %s\n  }%s\n"):format(
      vim.json.encode(title),
      vim.json.encode(ws.root),
      dir_block,
      comma
    )
  end
  chunks[#chunks + 1] = "}\n"
  return table.concat(chunks)
end

local function strip_jsonc(s)
  local out, i, n = {}, 1, #s
  local in_str, escape = false, false
  while i <= n do
    local c = s:sub(i, i)
    if in_str then
      out[#out + 1] = c
      if escape then
        escape = false
      elseif c == "\\" then
        escape = true
      elseif c == '"' then
        in_str = false
      end
      i = i + 1
    elseif c == '"' then
      in_str = true
      out[#out + 1] = c
      i = i + 1
    elseif c == "/" and s:sub(i + 1, i + 1) == "/" then
      i = s:find("\n", i) or (n + 1)
    elseif c == "/" and s:sub(i + 1, i + 1) == "*" then
      local close = s:find("*/", i + 2, true)
      i = close and (close + 2) or (n + 1)
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

local function write_file(path, body)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = assert(io.open(path, "w"))
  f:write(body)
  f:close()
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function ingest_title(title, v)
  if type(title) ~= "string" or title == "" or type(v) ~= "table" then
    return
  end
  local root = normalize(v.root or "")
  if root == "" then
    return
  end
  local extra = uniq_dirs(v.dirs or {})
  extra = vim.tbl_filter(function(d)
    return d ~= root
  end, extra)
  entries[title] = { title = title, root = root, dirs = extra }
end

local function save_user()
  write_file(user_file, encode_user())
end

local function save_meta()
  write_file(
    meta_file,
    vim.json.encode({
      active = active_title,
      last_used = last_used,
    })
  )
end

local function load_meta()
  local content = read_file(meta_file)
  if not content or content == "" then
    return
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return
  end
  active_title = data.active
  last_used = data.last_used or {}
end

local function load_user()
  entries = {}
  local content = read_file(user_file)
  if not content or vim.trim(content) == "" then
    return
  end
  local ok, data = pcall(vim.json.decode, strip_jsonc(content))
  if not ok or type(data) ~= "table" then
    vim.notify("workspaces.json: invalid JSON", vim.log.levels.ERROR)
    return
  end

  -- Old v1/v2/v3: { version, entries keyed by root, active_root }
  if data.entries or data.version then
    for root, v in pairs(data.entries or {}) do
      if type(v) == "table" then
        local title = v.title or v.name or default_title(v.root or root)
        ingest_title(title, {
          root = v.root or root,
          dirs = v.dirs,
        })
        if v.last_used then
          last_used[title] = v.last_used
        end
      end
    end
    if data.active_root then
      for title, ws in pairs(entries) do
        if ws.root == normalize(data.active_root) then
          active_title = title
          break
        end
      end
    end
    save_user()
    save_meta()
    return
  end

  for title, v in pairs(data) do
    ingest_title(title, v)
  end
end

local function list_workspaces()
  local list = {}
  for _, ws in pairs(entries) do
    list[#list + 1] = ws
  end
  table.sort(list, function(a, b)
    local la, lb = last_used[a.title] or 0, last_used[b.title] or 0
    if la ~= lb then
      return la > lb
    end
    return a.title < b.title
  end)
  return list
end

local function find_title_for_path(path)
  path = normalize(path)
  local best, best_len = nil, 0
  for title, ws in pairs(entries) do
    if path == ws.root or path:find(ws.root .. "/", 1, true) == 1 then
      if #ws.root > best_len then
        best = title
        best_len = #ws.root
      end
    end
  end
  return best
end

local function folder_path(folder)
  return vim.uri_to_fname(folder.uri):gsub("/$", "")
end

local function sync_lsp_folders(ws)
  if not ws then
    return
  end
  local wanted = { [ws.root] = true }
  for _, d in ipairs(ws.dirs) do
    wanted[d] = true
  end
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client:supports_method("workspace/didChangeWorkspaceFolders") then
      local folders = client.workspace_folders or {}
      local origin = client.root_dir and normalize(client.root_dir) or nil
      if folders[1] then
        origin = folder_path(folders[1])
      end
      local present = {}
      for _, folder in ipairs(folders) do
        local path = folder_path(folder)
        present[path] = true
        if path ~= origin and not wanted[path] then
          client:_remove_workspace_folder(path)
        end
      end
      for d in pairs(wanted) do
        if not present[d] then
          client:_add_workspace_folder(d)
        end
      end
    end
  end
end

function M.root()
  local ws = M.current()
  if ws then
    return ws.root
  end
  return normalize(vim.fn.getcwd())
end

function M.current()
  if active_title and entries[active_title] then
    return entries[active_title]
  end
  local title = find_title_for_path(vim.fn.getcwd())
  return title and entries[title] or nil
end

function M.search_dirs()
  local ws = M.current()
  if not ws then
    return { M.root() }
  end
  return uniq_dirs(vim.list_extend({ ws.root }, ws.dirs))
end

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

function M.pick_files()
  require("snacks").picker.files(M.picker_opts())
end

function M.pick_grep()
  require("snacks").picker.grep(M.picker_opts())
end

function M.pick_grep_word()
  require("snacks").picker.grep_word(M.picker_opts())
end

---@param title string
---@param opts? {silent?: boolean, no_cd?: boolean}
function M.activate(title, opts)
  opts = opts or {}
  local ws = entries[title]
  if not ws then
    if not opts.silent then
      vim.notify("Unknown workspace: " .. title, vim.log.levels.WARN)
    end
    return
  end
  active_title = title
  last_used[title] = os.time()
  save_meta()
  if vim.fn.isdirectory(ws.root) == 0 then
    vim.notify("Workspace root missing: " .. ws.root, vim.log.levels.WARN)
    return
  end
  if not opts.no_cd and vim.fn.getcwd() ~= ws.root then
    vim.cmd.cd(vim.fn.fnameescape(ws.root))
  end
  sync_lsp_folders(ws)
  if not opts.silent then
    vim.notify("Workspace: " .. title, vim.log.levels.INFO)
  end
end

function M.add_dir(dir)
  local ws = M.current()
  if not ws then
    vim.notify("No workspace — add a title entry in <leader>we", vim.log.levels.WARN)
    return
  end
  if not dir or dir == "" then
    return
  end
  dir = normalize(dir)
  if dir == ws.root then
    vim.notify("Already workspace root: " .. dir, vim.log.levels.INFO)
    return
  end
  for _, d in ipairs(ws.dirs) do
    if d == dir then
      vim.notify("Already in workspace search dirs: " .. dir, vim.log.levels.INFO)
      return
    end
  end
  table.insert(ws.dirs, dir)
  ws.dirs = uniq_dirs(ws.dirs)
  save_user()
  sync_lsp_folders(ws)
  vim.notify("Added search dir: " .. dir)
end

--- Create a workspace for cwd if none, then open workspaces.json on that entry.
function M.edit()
  load_user()
  local cwd = normalize(vim.fn.getcwd())
  local title = find_title_for_path(cwd)
  if not title then
    title = unique_title(default_title(cwd))
    entries[title] = { title = title, root = cwd, dirs = {} }
    save_user()
  end
  M.activate(title, { silent = true, no_cd = true })

  vim.cmd.split()
  vim.cmd.edit(vim.fn.fnameescape(user_file))
  vim.bo.filetype = "jsonc"
  pcall(vim.cmd.checktime)
  vim.fn.search(vim.fn.escape(vim.json.encode(title), [[\]]))
  vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = true, silent = true, desc = "Close" })
end

function M.open_picker()
  load_user()
  local items = vim.tbl_map(function(ws)
    return {
      text = ws.title,
      title = ws.title,
      file = ws.root,
    }
  end, list_workspaces())

  if #items == 0 then
    vim.notify("No workspaces — <leader>we creates one for this directory", vim.log.levels.WARN)
    return
  end

  require("snacks").picker.pick({
    title = "Workspaces",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item and item.title then
        M.activate(item.title)
      end
    end,
  })
end

function M.setup()
  load_meta()
  load_user()
  local cwd = normalize(vim.fn.getcwd())
  local cwd_title = find_title_for_path(cwd)
  if cwd_title then
    M.activate(cwd_title, { silent = true, no_cd = true })
  else
    -- Started outside any saved workspace: keep cwd, don't restore last active root.
    active_title = nil
    save_meta()
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = user_file,
    callback = function()
      load_user()
      local ws = M.current()
      if ws then
        sync_lsp_folders(ws)
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function()
      local ws = M.current()
      if ws then
        sync_lsp_folders(ws)
      end
    end,
  })

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { desc = desc })
  end
  map("<leader>wo", M.open_picker, "Workspace: Open")
  map("<leader>we", M.edit, "Workspace: Edit config")
  map("<leader>Wo", M.open_picker, "Workspace: Open")
  map("<leader>We", M.edit, "Workspace: Edit config")
end

return M
