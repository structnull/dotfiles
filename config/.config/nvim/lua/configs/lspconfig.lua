require("nvchad.configs.lspconfig").defaults()
local servers = {
  "clangd",
  "html",
  "ruff",
  "pyright",
  "oxlint",
  "cssls",
  "html",
  "rust_analyzer",
  "marksman",
  "jsonls",
}

vim.lsp.enable(servers)

local function on_attach(_, bufnr)
  local map = vim.keymap.set
  local opts = { buffer = bufnr }

  map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
  map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
  map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
  map("n", "gs", "<cmd>Telescope lsp_document_symbols<CR>", opts)
  map("n", "gS", "<cmd>Telescope lsp_workspace_symbols<CR>", opts)
  map("n", "gy", "<cmd>Telescope lsp_type_definitions<CR>", opts)
end

vim.lsp.config("*", {
  on_attach = on_attach,
})

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
