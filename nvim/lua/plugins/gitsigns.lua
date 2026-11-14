vim.pack.add { 'https://github.com/lewis6991/gitsigns.nvim' }

local function nav_hunk(direction, diff_key)
  return function()
    if vim.wo.diff then
      vim.cmd.normal { diff_key, bang = true }
      return
    end
    require('gitsigns').nav_hunk(direction)
  end
end

require('gitsigns').setup {
  on_attach = function(bufnr)
    local gitsigns = require 'gitsigns'

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map('n', ']c', nav_hunk('next', ']c'), 'Jump to next git [c]hange')
    map('n', '[c', nav_hunk('prev', '[c'), 'Jump to previous git [c]hange')

    map('v', '<leader>hs', function()
      gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, 'git [s]tage hunk')
    map('v', '<leader>hr', function()
      gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, 'git [r]eset hunk')

    map('n', '<leader>hs', gitsigns.stage_hunk, 'git [s]tage hunk')
    map('n', '<leader>hr', gitsigns.reset_hunk, 'git [r]eset hunk')
    map('n', '<leader>hS', gitsigns.stage_buffer, 'git [S]tage buffer')
    map('n', '<leader>hu', gitsigns.stage_hunk, 'git [u]ndo stage hunk')
    map('n', '<leader>hR', gitsigns.reset_buffer, 'git [R]eset buffer')
    map('n', '<leader>hp', gitsigns.preview_hunk, 'git [p]review hunk')
    map('n', '<leader>hb', gitsigns.blame_line, 'git [b]lame line')
    map('n', '<leader>hd', gitsigns.diffthis, 'git [d]iff against index')
    map('n', '<leader>hD', function()
      gitsigns.diffthis '@'
    end, 'git [D]iff against last commit')
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, '[T]oggle git show [b]lame line')
    map('n', '<leader>tD', gitsigns.preview_hunk_inline, '[T]oggle git show [D]eleted')
  end,
}
