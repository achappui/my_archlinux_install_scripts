local keymap = vim.keymap.set

-- diagnostics
keymap("n", "<leader>e", vim.diagnostic.open_float)
keymap("n", "[d", vim.diagnostic.goto_prev)
keymap("n", "]d", vim.diagnostic.goto_next)
-- Chercher des fichiers
vim.keymap.set('n', '<leader>ff', fzf.files, { desc = 'FZF Fichiers' })
-- Chercher dans le texte (grep)
vim.keymap.set('n', '<leader>fg', fzf.live_grep, { desc = 'FZF Grep' })
-- Chercher dans les buffers ouverts
vim.keymap.set('n', '<leader>fb', fzf.buffers, { desc = 'FZF Buffers' })
-- Chercher dans l'historique des commandes
vim.keymap.set('n', '<leader>fh', fzf.help_tags, { desc = 'FZF Aide' })
