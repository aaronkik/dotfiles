vim.pack.add { 'https://github.com/stevearc/conform.nvim' }

local format_on_save_disabled = { c = true, cpp = true }

require('conform').setup {
  notify_on_error = false,
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = function(bufnr)
    if format_on_save_disabled[vim.bo[bufnr].filetype] then
      return nil
    end
    return { timeout_ms = 500 }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    javascript = { 'prettier', stop_after_first = true },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
  require('conform').format { async = true }
end, { desc = '[F]ormat buffer' })
