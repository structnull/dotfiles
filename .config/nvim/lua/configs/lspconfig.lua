local on_attach = require("nvchad.configs.lspconfig").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities
local lspconfig = require "lspconfig"
local servers = {
  "clangd",
  "html",
  "pyright",
  "astro",
  "ts_ls",
  "cssls",
  "marksman",
  "jsonls",
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end
