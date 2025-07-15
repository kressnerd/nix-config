{
  config,
  pkgs,
  ...
}: {
  programs.vim = {
    enable = true;

    settings = {
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      number = true;
      relativenumber = true;
      ignorecase = true;
      smartcase = true;
      undofile = true;
      hidden = true;
    };

    extraConfig = ''
      " Enable syntax highlighting
      syntax on

      " Better search highlighting
      set hlsearch
      set incsearch

      " Show matching brackets
      set showmatch

      " Enable mouse support
      set mouse=a

      " Centralize undo files instead of cluttering directories
      set undodir=~/.vim/undodir
      " Also centralize backup and swap files
      set backupdir=~/.vim/backupdir
      set directory=~/.vim/swapdir

      " Create directories if they don't exist
      if !isdirectory($HOME."/.vim/undodir")
        call mkdir($HOME."/.vim/undodir", "p", 0700)
      endif
      if !isdirectory($HOME."/.vim/backupdir")
        call mkdir($HOME."/.vim/backupdir", "p", 0700)
      endif
      if !isdirectory($HOME."/.vim/swapdir")
        call mkdir($HOME."/.vim/swapdir", "p", 0700)
      endif

      " Set leader key to space
      let mapleader=" "

      " Quick save and quit
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>

      " Clear search highlighting
      nnoremap <leader><space> :nohlsearch<CR>
    '';
  };
}
