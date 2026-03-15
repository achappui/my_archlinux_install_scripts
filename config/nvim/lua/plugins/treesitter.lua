return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  branch = "master",

  opts = {
    ensure_installed = {
      "c",
      "cpp",
      "python",
      "typescript",
      "html",
      "css",
      "bash",
      "lua",
      "go",
      "rust",
      "json",
      "yaml",
      "markdown"
    },

    highlight = {
      enable = true
    },

    indent = {
      enable = true
    },
  },

  config = function(_, opts)

    require("nvim-treesitter.configs").setup(opts)

    require("nvim-treesitter.install").compilers = {
      "clang"
    }

  end,
}
