vim.pack.add { 'https://github.com/nvim-mini/mini.nvim' }

require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()

-- Moved off `an`/`in` so Neovim's built-in treesitter incremental selection keeps them.
require('mini.ai').setup {
  mappings = {
    around_next = 'aa',
    inside_next = 'ii',
  },
  n_lines = 500,
}

require('mini.surround').setup()

local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }

---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return '%2l:%-2v'
end
