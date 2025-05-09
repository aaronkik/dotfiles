--  To check the current status of your plugins, run :Lazy
--  Press `?` in this menu for help. Use `:q` to close the window
--  To update plugins :Lazy update

local plugins = {
    require 'plugins/autopairs',
    require 'plugins/vim-sleuth',
    require 'plugins/gitsigns',
    require 'plugins/which-key',
    require 'plugins/telescope',
    require 'plugins/lspconfig',
    require 'plugins/conform',
    require 'plugins/blink-cmp',
    require 'plugins/catppuccin',
    require 'plugins/debug',
    require 'plugins/todo-comments',
    require 'plugins/mini',
    require 'plugins/treesitter',
    require 'plugins/neo-tree',
}

local options = {}

require('lazy').setup(plugins, options)

vim.cmd.colorscheme('catppuccin-frappe')

-- vim: ts=2 sts=2 sw=2 et
