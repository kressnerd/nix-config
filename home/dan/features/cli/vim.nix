{ config, pkgs, ... }:

{
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
      syntax on

      set hlsearch
      set incsearch

      set showmatch

      set mouse=a

      let mapleader=" "

      " Quick save and quit
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>

      nnoremap <leader><space> :nohlsearch<CR>
    '';
  };
}
