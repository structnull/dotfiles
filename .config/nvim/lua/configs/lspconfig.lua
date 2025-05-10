local servers = {
  "clangd",
  "html",
  "ruff",
  "pyright",
  "oxlint",
  "cssls",
  "rust_analyzer",
  "marksman",
  "jsonls",
}

vim.lsp.enable(servers)

vim.lsp.config("pyright", {
  settings = {
    pyright = {
      disableOrganizeImports = true,
    },
    python = {
      analysis = {
        ignore = { "*" },
      },
    },
  },
})
