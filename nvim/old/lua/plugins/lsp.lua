-- Fixed LazyVim approach - ensure custom setup runs
return {
  -- Treesitter for C++
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "cpp" } },
  },

  -- LazyVim clangd setup
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "p00f/clangd_extensions.nvim",
    },
    config = function()
      require("mason").setup()
      
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")
      
      -- Get capabilities
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.offsetEncoding = { "utf-16" }
      
      -- Try to get cmp capabilities if available
      pcall(function()
        capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
      end)
      
      -- Try to get blink.cmp capabilities if available  
      pcall(function()
        capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
      end)

      -- Setup mason-lspconfig but EXCLUDE clangd from auto-setup
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd" },
        handlers = {
          -- Default handler for other servers
          function(server_name)
            if server_name ~= "clangd" then -- Skip clangd, we'll handle it manually
              lspconfig[server_name].setup({
                capabilities = capabilities,
              })
            end
          end,
        },
      })

      -- MANUAL clangd setup - this should override default behavior
      local clangd_opts = {
        capabilities = capabilities,
        root_dir = function(fname)
          -- LazyVim's exact root detection logic
          return util.root_pattern(
            "Makefile",
            "configure.ac",
            "configure.in", 
            "config.h.in",
            "meson.build",
            "meson_options.txt",
            "build.ninja"
          )(fname) or util.root_pattern("compile_commands.json", "compile_flags.txt")(
            fname
          ) or util.find_git_ancestor(fname)
        end,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
        on_attach = function(client, bufnr)
          -- LazyVim keybinding
          vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", 
            { buffer = bufnr, desc = "Switch Source/Header (C/C++)" })
            
          -- Add debug info
          print("🚀 Custom clangd attached to buffer " .. bufnr)
          print("🔍 Root dir: " .. (client.config.root_dir or "unknown"))
          print("🔧 Command: " .. table.concat(client.config.cmd, " "))
          print("⚙️  Init options: " .. vim.inspect(client.config.init_options))
        end,
      }

      -- Try clangd_extensions first
      local ok, clangd_extensions = pcall(require, "clangd_extensions")
      if ok then
        print("✅ Using clangd_extensions.setup()")
        
        local clangd_ext_opts = {
          inlay_hints = { inline = false },
          ast = {
            role_icons = {
              type = "", declaration = "", expression = "",
              specifier = "", statement = "", ["template argument"] = "",
            },
            kind_icons = {
              Compound = "", Recovery = "", TranslationUnit = "",
              PackExpansion = "", TemplateTypeParm = "", TemplateTemplateParm = "",
              TemplateParamObject = "",
            },
          },
        }
        
        clangd_extensions.setup(vim.tbl_deep_extend("force", clangd_ext_opts, { server = clangd_opts }))
      else
        print("⚠️ clangd_extensions not found, using direct lspconfig setup")
        lspconfig.clangd.setup(clangd_opts)
      end
    end,
  },

  -- clangd_extensions (LazyVim style)
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    config = function() end,
    opts = {
      inlay_hints = { inline = false },
      ast = {
        role_icons = {
          type = "", declaration = "", expression = "",
          specifier = "", statement = "", ["template argument"] = "",
        },
        kind_icons = {
          Compound = "", Recovery = "", TranslationUnit = "",
          PackExpansion = "", TemplateTypeParm = "", TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    },
  },

  -- Enhanced completion with clangd
  {
    "hrsh7th/nvim-cmp", 
    optional = true,
    opts = function(_, opts)
      local ok, clangd_cmp = pcall(require, "clangd_extensions.cmp_scores")
      if ok then
        opts.sorting = opts.sorting or {}
        opts.sorting.comparators = opts.sorting.comparators or {}
        table.insert(opts.sorting.comparators, 1, clangd_cmp)
      end
    end,
  },
}
