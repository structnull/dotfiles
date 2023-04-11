local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

capabilities.textDocument.completion.completionItem.snippetSupport = true

local lspconfig = require "lspconfig"
local servers = {
    "clangd",
    "html",
    "pyright",
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
