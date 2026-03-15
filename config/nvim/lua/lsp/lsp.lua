-- Diagnostics
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
  },
})

-- clang
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "-j=4", "--clang-tidy" },
})

-- go
vim.lsp.config("gopls", {})

-- rust
vim.lsp.config("rust_analyzer", {})

-- bun runtime servers
local function bun_server(name, binary)
  vim.lsp.config(name, {
    cmd = { "bunx", "--bun", binary, "--stdio" },
  })
end

bun_server("pyright", "pyright-langserver")
bun_server("ts_ls", "typescript-language-server")
bun_server("bashls", "bash-language-server")
bun_server("cssls", "css-languageserver")
bun_server("html", "html-languageserver")

-- enable servers
vim.lsp.enable({
  "clangd",
  "gopls",
  "rust_analyzer",
  "pyright",
  "ts_ls",
  "bashls",
  "cssls",
  "html",
})

-- attach event
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)

    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client.server_capabilities.completionProvider then
      vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    end

  end,
})
