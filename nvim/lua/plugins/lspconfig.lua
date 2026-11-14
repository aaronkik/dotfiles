vim.pack.add {
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/mason-org/mason-lspconfig.nvim',
  'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
}

require('fidget').setup {}

local severity = vim.diagnostic.severity
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [severity.ERROR] = '󰅚 ',
      [severity.WARN] = '󰀪 ',
      [severity.INFO] = '󰋽 ',
      [severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = { source = 'if_many', spacing = 2 },
}

local highlight_group = vim.api.nvim_create_augroup('lsp-highlight', { clear = true })

local function highlight_references(bufnr)
  vim.api.nvim_clear_autocmds { group = highlight_group, buffer = bufnr }
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    buffer = bufnr,
    group = highlight_group,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    buffer = bufnr,
    group = highlight_group,
    callback = vim.lsp.buf.clear_references,
  })
end

local function map_inlay_hint_toggle(bufnr)
  vim.keymap.set('n', '<leader>th', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
  end, { buffer = bufnr, desc = 'LSP: [T]oggle Inlay [H]ints' })
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    vim.keymap.set('n', 'grD', vim.lsp.buf.declaration, { buffer = event.buf, desc = 'LSP: [G]oto [D]eclaration' })

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    if client:supports_method('textDocument/documentHighlight', event.buf) then
      highlight_references(event.buf)
    end

    if client:supports_method('textDocument/inlayHint', event.buf) then
      map_inlay_hint_toggle(event.buf)
    end
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds { group = highlight_group, buffer = event.buf }
  end,
})

local function has_luarc(path)
  return vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')
end

local function add_neovim_runtime(client)
  local workspace = client.workspace_folders and client.workspace_folders[1].name
  if workspace and workspace ~= vim.fn.stdpath 'config' and has_luarc(workspace) then
    return
  end

  client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
    runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
    workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file('', true) },
  })
end

---@type table<string, vim.lsp.Config>
local servers = {
  lua_ls = {
    on_init = add_neovim_runtime,
    settings = {
      Lua = {
        completion = { callSnippet = 'Replace' },
      },
    },
  },
}

require('mason').setup {}
require('mason-lspconfig').setup { automatic_enable = false }

local tools = vim.tbl_keys(servers)
vim.list_extend(tools, { 'stylua' })
require('mason-tool-installer').setup { ensure_installed = tools }

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end
