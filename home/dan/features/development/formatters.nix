{
  config,
  pkgs,
  lib,
  ...
}: {
  # Code formatters for various languages
  home.packages = with pkgs; [
    # Nix formatters
    alejandra # Modern, opinionated Nix formatter
    nixpkgs-fmt # Traditional Nix formatter (for compatibility)

    # Language-specific formatters
    black # Python formatter
    rustfmt # Rust formatter
    nodePackages.prettier # JavaScript/TypeScript/CSS/HTML formatter
    shfmt # Shell script formatter
    stylua # Lua formatter

    # Additional development tools
    treefmt # Multi-language formatter wrapper
  ];

  # Shell integration for formatters
  programs.zsh = {
    shellAliases = {
      # Nix formatting aliases
      "fmt-nix" = "alejandra .";
      "fmt-nix-check" = "alejandra --check .";
      "fmt-nix-legacy" = "nixpkgs-fmt";

      # Multi-format with treefmt
      "fmt-all" = "treefmt";
      "fmt-check" = "treefmt --fail-on-change";

      # Language-specific formatting
      "fmt-py" = "black";
      "fmt-rust" = "rustfmt";
      "fmt-js" = "prettier --write";
      "fmt-sh" = "shfmt -w";
    };

    initContent = ''
      # Format current directory with appropriate formatter
      fmt() {
        local file_type="$1"

        case "$file_type" in
          nix|*.nix)
            echo "Formatting Nix files with Alejandra..."
            alejandra .
            ;;
          py|python|*.py)
            echo "Formatting Python files with Black..."
            black .
            ;;
          js|javascript|ts|typescript|*.js|*.ts)
            echo "Formatting JavaScript/TypeScript files with Prettier..."
            prettier --write "**/*.{js,ts,jsx,tsx,json,css,md}"
            ;;
          rust|*.rs)
            echo "Formatting Rust files..."
            find . -name "*.rs" -exec rustfmt {} \;
            ;;
          sh|shell|*.sh)
            echo "Formatting shell scripts..."
            find . -name "*.sh" -exec shfmt -w {} \;
            ;;
          all|*)
            echo "Running treefmt for multi-language formatting..."
            if command -v treefmt >/dev/null 2>&1; then
              treefmt
            else
              echo "treefmt not available, running Alejandra on Nix files..."
              alejandra .
            fi
            ;;
        esac
      }

      # Format check function
      fmt-check() {
        local file_type="''${1:-nix}"

        case "$file_type" in
          nix|*.nix)
            alejandra --check .
            ;;
          all)
            if command -v treefmt >/dev/null 2>&1; then
              treefmt --fail-on-change
            else
              alejandra --check .
            fi
            ;;
        esac
      }
    '';
  };

  # Optional: Create a treefmt configuration for multi-language formatting
  home.file.".treefmt.toml".text = ''
    [formatter.alejandra]
    command = "alejandra"
    includes = ["*.nix"]

    [formatter.black]
    command = "black"
    includes = ["*.py"]

    [formatter.prettier]
    command = "prettier"
    options = ["--write"]
    includes = ["*.js", "*.ts", "*.jsx", "*.tsx", "*.json", "*.css", "*.md", "*.yaml", "*.yml"]

    [formatter.rustfmt]
    command = "rustfmt"
    includes = ["*.rs"]

    [formatter.shfmt]
    command = "shfmt"
    options = ["-w"]
    includes = ["*.sh"]
  '';

  # Environment variables for formatters
  home.sessionVariables = {
    # Alejandra configuration
    ALEJANDRA_VERBOSITY = "normal";

    # Black configuration
    BLACK_LINE_LENGTH = "88";

    # Prettier configuration
    PRETTIER_CONFIG_PRECEDENCE = "prefer-file";
  };
}
