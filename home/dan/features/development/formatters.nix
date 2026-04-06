{ pkgs, ... }:
{
  # Code formatters for various languages
  home = {
    packages = with pkgs; [
      # Nix formatters
      nixfmt-rfc-style # Official Nix formatter (RFC 166)
      deadnix # Detect unused bindings and dead code in Nix files
      statix # Lint Nix code for anti-patterns and suggest idiomatic improvements

      # Language-specific formatters
      black # Python formatter
      rustfmt # Rust formatter
      nodePackages.prettier # JavaScript/TypeScript/CSS/HTML formatter
      shfmt # Shell script formatter
      stylua # Lua formatter

      # Additional development tools
      treefmt # Multi-language formatter wrapper
      vale # Syntax-aware prose linter
    ];

    # Optional: Create a treefmt configuration for multi-language formatting
    file.".treefmt.toml".text = ''
      [formatter.nixfmt]
      command = "nixfmt"
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
    sessionVariables = {
      # Black configuration
      BLACK_LINE_LENGTH = "88";

      # Prettier configuration
      PRETTIER_CONFIG_PRECEDENCE = "prefer-file";
    };
  };

  # Shell integration for formatters
  programs.fish = {
    shellAliases = {
      # Nix formatting aliases
      "fmt-nix" = "nix fmt .";
      "fmt-nix-check" = "nix fmt -- --check .";

      # Multi-format with treefmt
      "fmt-all" = "treefmt";
      "fmt-check" = "treefmt --fail-on-change";

      # Language-specific formatting
      "fmt-py" = "black";
      "fmt-rust" = "rustfmt";
      "fmt-js" = "prettier --write";
      "fmt-sh" = "shfmt -w";
    };

    functions = {
      # Format current directory with appropriate formatter
      fmt = ''
        set file_type $argv[1]

        switch "$file_type"
          case nix '*.nix'
            echo "Formatting Nix files with nixfmt..."
            nix fmt .
          case py python '*.py'
            echo "Formatting Python files with Black..."
            black .
          case js javascript ts typescript '*.js' '*.ts'
            echo "Formatting JavaScript/TypeScript files with Prettier..."
            prettier --write "**/*.{js,ts,jsx,tsx,json,css,md}"
          case rust '*.rs'
            echo "Formatting Rust files..."
            find . -name "*.rs" -exec rustfmt {} \;
          case sh shell '*.sh'
            echo "Formatting shell scripts..."
            find . -name "*.sh" -exec shfmt -w {} \;
          case all '*'
            echo "Running treefmt for multi-language formatting..."
            if type -q treefmt
              treefmt
            else
              echo "treefmt not available, running nixfmt on Nix files..."
              nix fmt .
            end
        end
      '';

      # Format check function
      fmt-check = ''
        set file_type $argv[1]
        if test -z "$file_type"
          set file_type nix
        end

        switch "$file_type"
          case nix '*.nix'
            nix fmt -- --check .
          case all
            if type -q treefmt
              treefmt --fail-on-change
            else
              nix fmt -- --check .
            end
        end
      '';
    };
  };
}
