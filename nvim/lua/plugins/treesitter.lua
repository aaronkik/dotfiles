vim.pack.add { { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' } }

local treesitter = require 'nvim-treesitter'

treesitter.install { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

local available_parsers = treesitter.get_available()

local function attach(bufnr, language)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if not vim.treesitter.language.add(language) then
    return
  end

  vim.treesitter.start(bufnr, language)

  if vim.treesitter.query.get(language, 'indents') then
    vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

local function needs_install(language)
  return vim.list_contains(available_parsers, language) and not vim.list_contains(treesitter.get_installed 'parsers', language)
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-attach', { clear = true }),
  callback = function(event)
    local language = vim.treesitter.language.get_lang(event.match)
    if not language then
      return
    end

    if not needs_install(language) then
      attach(event.buf, language)
      return
    end

    treesitter.install(language):await(function()
      attach(event.buf, language)
    end)
  end,
})
