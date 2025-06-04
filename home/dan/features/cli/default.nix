{pkgs, ...}: {
  imports = [
    ./fish

    ./bash.nix
    ./bat.nix
    ./direnv.nix
    ./gh.nix
    ./git.nix
    ./gpg.nix
    ./jujutsu.nix
    ./lyrics.nix
#    ./nushell.nix
#    ./nix-index.nix
    ./pfetch.nix
    ./ssh.nix
#    ./xpo.nix
    ./fzf.nix
    ./jira.nix
  ];
  home.packages = with pkgs; [
    comma # Install and run programs by sticking a , before them
    distrobox # Nice escape hatch, integrates docker images with my environment

    bc # Calculator
    bottom # System viewer top clone
    ncdu # TUI disk usage
    eza # Better ls
    ripgrep # Better grep
    fd # Better find
    httpie # Better curl
    diffsitter # Better diff
    jq # JSON pretty printer and manipulator
    trekscii # Cute startrek cli printer
    timer # To help with paralysis

    nixd # Nix LSP
    alejandra # Nix formatter
    nixfmt-rfc-style
    nvd # Differ
    nix-diff # Differ, more detailed
    nix-output-monitor
    nh # Nice wrapper for NixOS and HM
    
#    # Rust clones of commmon tools
#    bat # cat with syntax highlighting
#    lsd # fancy ls like exa
#    diffr # diff with colors
#    delta # diff for git
#    difftastic # slow colorfull diff
#    ouch # com-/decompress everything
#    macchina # system information
#    sd # sed clone
#    procs # modern ps clone
#    xcp # extended cp
#    rm-improved # rm clone
#    rargs # awk and xargs clone with pattern matching
#    runiq # remove duplicate lines from input
#    zoxide # better cd

#    # Rust directory and disk usage tools
#    dust # du clone
#    diskus # disk usage info
#    dutree # du clone
#    duf # df alt
#    dua # du clone

 #   # Rust other tools
 #   skim # fzf clone
 #   starship # shell prompt
 #   topgrade # upgrade everything
 #   bingrep # binary grep
 #   broot # interactive tree
 #   dupe-krill # file deduplicator
 #   ruplacer # find and replace
 #   fastmod # find and replace
 #   genact # activity generator
 #   grex # regx builder
 #   bandwhich # bandwith monitor
 #   ffsend # firefox send file from cli
 #   pastel # color info
 #   miniserve # mini http server
 #   monolith # bundle a webpage in a single file
 #   tealdeer # tldr clone to read man pages
 #   tokei # code statistics

#    # data handling
#    jql # JSON
#    xsv # CSV
#    hexyl # HEX viewer
  ];
}
