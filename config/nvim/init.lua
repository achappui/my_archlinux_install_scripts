local install_path = vim.fn.stdpath('data')..'/site/autoload/plug.vim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({'sh', '-c',
    'curl -fLo '..install_path..' --create-dirs '..
    'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'})
  vim.cmd('autocmd VimEnter * PlugInstall --sync | source $MYVIMRC')
end

require('plugins')

vim.cmd 'syntax on'
vim.cmd 'colorscheme onedark'

vim.g.ale_linters_explicit = 1
vim.g.ale_fix_on_save = 1
vim.g.ale_linters = {
  python = {'flake8'},
  typescript = {'tsc'},
  c = {'gcc'},
  cpp = {'g++'},
  css = {'stylelint'},
  html = {'tidy'},
  sh = {'shellcheck'},
}