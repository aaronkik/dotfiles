vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local lint = require 'lint'

lint.linters_by_ft = {
  markdown = { 'markdownlint' },
}

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = vim.api.nvim_create_augroup('lint', { clear = true }),
  callback = function()
    if not vim.bo.modifiable then
      return
    end
    lint.try_lint()
  end,
})
