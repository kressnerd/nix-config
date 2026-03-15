{pkgs, ...}: {
  home.packages = [pkgs.fnm];

  # Automatic Node version switching when entering directories with
  # .nvmrc or .node-version files.
  programs.fish.interactiveShellInit = ''
    fnm env --use-on-cd --shell fish | source
  '';
}
