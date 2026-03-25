return {
  "ibhagwan/fzf-lua",
  -- Les dépendances optionnelles pour les icônes
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- On appelle la configuration par défaut
    require("fzf-lua").setup({})
  end,
}
