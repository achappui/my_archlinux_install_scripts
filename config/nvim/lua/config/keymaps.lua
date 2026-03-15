local keymap = vim.keymap.set

-- diagnostics
keymap("n", "<leader>e", vim.diagnostic.open_float)
keymap("n", "[d", vim.diagnostic.goto_prev)
keymap("n", "]d", vim.diagnostic.goto_next)
