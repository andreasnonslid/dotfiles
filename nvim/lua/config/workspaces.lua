local M = {}

local state_file = vim.fn.stdpath("state") .. "/workspaces.json"
local startup_cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/$", "")
local workspaces = {}

local function normalize(dir)
  return vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
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
  if ok and type(data) == "table" then
    workspaces = data
  end
end

local function save()
  vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
  local f = io.open(state_file, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(workspaces))
  f:close()
end

local function key()
  return startup_cwd
end

function M.current()
  return workspaces[key()]
end

function M.dirs()
  local ws = M.current()
  return ws and ws.dirs or {}
end

function M.create_for_cwd()
  local k = key()
  if workspaces[k] then
    vim.notify("Workspace already exists for " .. k, vim.log.levels.INFO)
    return
  end
  workspaces[k] = { dirs = { k } }
  save()
  vim.notify("Workspace created: " .. k)
end

function M.add_dir(dir)
  local k = key()
  if not workspaces[k] then
    vim.notify("No workspace; create one with :WorkspaceCreate", vim.log.levels.WARN)
    return
  end
  if not dir or dir == "" then
    return
  end
  dir = normalize(dir)
  for _, d in ipairs(workspaces[k].dirs) do
    if d == dir then
      vim.notify("Already in workspace: " .. dir, vim.log.levels.INFO)
      return
    end
  end
  table.insert(workspaces[k].dirs, dir)
  save()
  vim.notify("Added: " .. dir)
end

function M.edit()
  local k = key()
  if not workspaces[k] then
    vim.notify("No workspace; create one with :WorkspaceCreate", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {
    "# Workspace: " .. k,
    "# One directory per line. Lines starting with # are ignored.",
    "# Save (:w) to apply, q to close.",
    "",
  }
  vim.list_extend(lines, workspaces[k].dirs)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "workspace"
  vim.api.nvim_buf_set_name(buf, "workspace://" .. k)

  local width = math.min(100, math.floor(vim.o.columns * 0.7))
  local height = math.min(20, math.floor(vim.o.lines * 0.5))
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
      local dirs = {}
      for _, line in ipairs(current) do
        line = vim.trim(line)
        if line ~= "" and not line:match("^#") then
          table.insert(dirs, normalize(line))
        end
      end
      workspaces[k].dirs = dirs
      save()
      vim.bo[buf].modified = false
      vim.notify("Workspace saved (" .. #dirs .. " dirs)")
    end,
  })

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close" })
end

function M.setup()
  load()

  vim.api.nvim_create_user_command("WorkspaceCreate", M.create_for_cwd, {
    desc = "Create workspace for nvim startup dir",
  })
  vim.api.nvim_create_user_command("WorkspaceEdit", M.edit, {
    desc = "Edit current workspace search dirs",
  })
  vim.api.nvim_create_user_command("WorkspaceAdd", function(opts)
    M.add_dir(opts.args ~= "" and opts.args or vim.fn.getcwd())
  end, { nargs = "?", complete = "dir", desc = "Add dir to current workspace" })

  vim.keymap.set("n", "<leader>Wn", M.create_for_cwd, { desc = "Workspace: New (cwd)" })
  vim.keymap.set("n", "<leader>We", M.edit, { desc = "Workspace: Edit" })
end

return M
