-- Leader
vim.g.mapleader = " "

-- Core config
require("config.options")
require("config.keymaps")

-- Plugins
require("plugins.lazy")

-- LSP
require("lsp.lsp")

-- Colorscheme
vim.cmd.colorscheme("onedark")
