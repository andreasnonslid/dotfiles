-- Native vim.lsp.config + vim.lsp.enable; see lsp/*.lua
local lsp_servers = { "clangd", "pyright", "lua_ls", "ruff", "bashls" }

local function load_lsp_config(name)
  local rtp = vim.api.nvim_get_runtime_file("lsp/" .. name .. ".lua", false)
  if #rtp > 0 then
    return rtp[1]
  end
  local fallback = vim.fn.stdpath("config") .. "/lsp/" .. name .. ".lua"
  if vim.uv.fs_stat(fallback) then
    return fallback
  end
end

for _, name in ipairs(lsp_servers) do
  local path = load_lsp_config(name)
  if not path then
    vim.notify("LSP config file missing: " .. name, vim.log.levels.WARN)
  else
    local ok, cfg = pcall(dofile, path)
    if ok and type(cfg) == "table" then
      vim.lsp.config(name, cfg)
    else
      vim.notify("LSP config load failed: " .. name .. " (" .. tostring(cfg) .. ")", vim.log.levels.ERROR)
    end
  end
end
vim.lsp.enable(lsp_servers)

vim.opt.completeopt:append({ "menuone", "noselect", "popup" })

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Native LSP completion (0.11+). Global defaults cover gra/gri/grn/grr/grt/K.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    end

    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
    end

    -- Keep gd/gD — common convention; core defaults use tagfunc / gr* instead.
    map("gd", vim.lsp.buf.definition, "Go to Definition")
    vim.keymap.set("n", "<2-LeftMouse>", function()
      vim.lsp.buf.definition()
    end, { buffer = bufnr, desc = "LSP: Go to Definition (double-click)" })
    map("gD", vim.lsp.buf.declaration, "Go to Declaration")

    map("<leader>cd", vim.diagnostic.open_float, "Show Diagnostic")
    map("[d", function()
      vim.diagnostic.goto_prev()
    end, "Prev Diagnostic")
    map("]d", function()
      vim.diagnostic.goto_next()
    end, "Next Diagnostic")
  end,
})

-- Accept selected completion item; otherwise insert newline.
-- 0.12 has no vim.lsp.completion.accept(); CTRL-Y is the documented confirm.
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    local info = vim.fn.complete_info({ "selected" })
    if info.selected ~= -1 then
      return "<C-y>"
    end
  end
  return "<CR>"
end, { expr = true, desc = "Accept completion or newline" })

-- Snippet tab stops after LSP completion
vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    return vim.snippet.jump(1)
  end
  return "<Tab>"
end, { expr = true })
vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    return vim.snippet.jump(-1)
  end
  return "<S-Tab>"
end, { expr = true })
