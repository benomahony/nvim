return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local configs = require("lspconfig.configs")

      if not configs["oreilly-style-lsp"] then
        configs["oreilly-style-lsp"] = {
          default_config = {
            cmd = { "uv", "run", "--directory", "/Users/benomahony/Code/oreilly-style-lsp", "oreilly-lsp", "serve", "--stdio" },
            filetypes = { "markdown", "text", "asciidoc", "rst" },
            root_dir = function(fname)
              local util = require("lspconfig.util")
              return util.root_pattern(".git")(fname) or util.path.dirname(fname)
            end,
            settings = {},
            name = "oreilly-style-lsp",
          },
          docs = {
            description = "O'Reilly Style Guide Language Server",
          },
        }
      end

      opts.servers = opts.servers or {}
      opts.servers["oreilly-style-lsp"] = {
        on_attach = function(client, bufnr)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Show Style Info" })
        end,
      }

      return opts
    end,
  },
}
