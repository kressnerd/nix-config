{
  config,
  pkgs,
  pkgs-unstable,
  pkgs-dan-testing,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;

    profiles.default = {
      # Standard extensions from stable and unstable
      extensions =
        (with pkgs.vscode-extensions; [
          asciidoctor.asciidoctor-vscode
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          github.copilot
          kamadorueda.alejandra
        ])
        ++ (with pkgs-unstable.vscode-extensions; [
          github.copilot-chat
          jnoortheen.nix-ide
        ])
        ++ (with pkgs-dan-testing.vscode-extensions; [
          rooveterinaryinc.roo-cline
        ]);

      userSettings = {
        # Editor settings for AsciiDoc files
        "[asciidoc]" = {
          "editor.formatOnSave" = false; # AsciiDoc doesn't need auto-formatting
          "editor.insertSpaces" = true;
          "editor.quickSuggestions" = {
            "comments" = false;
            "other" = true;
            "strings" = false;
          };
          "editor.rulers" = [80 120];
          "editor.snippetSuggestions" = "top";
          "editor.suggest.showSnippets" = true;
          "editor.tabSize" = 2;
          "editor.wordWrap" = "on";
        };
        "asciidoc.extensions.enableKroki" = true;
        "asciidoc.preview.attributes" = {
          "experimental" = "";
          "icons" = "font";
          "linkattrs" = "";
          "sectanchors" = "";
          "toc" = "left";
          "toclevels" = "3";
        };
        "asciidoc.preview.breaks" = false;
        "asciidoc.preview.doubleClickToSwitchTab" = true;
        "asciidoc.preview.fontFamily" = "JetBrainsMono Nerd Font, -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', sans-serif";
        "asciidoc.preview.fontSize" = 14;
        "asciidoc.preview.lineHeight" = 1.6;
        "asciidoc.preview.markEditorSelection" = true;
        "asciidoc.preview.openMarkdownLinks" = true;
        "asciidoc.preview.refreshInterval" = 2000;
        "asciidoc.preview.scrollEditorWithPreview" = true;
        "asciidoc.preview.scrollPreviewWithEditor" = true;
        "asciidoc.preview.style" = ""; # Uses default styling that integrates with theme
        "asciidoc.preview.useEditorStyle" = false;
        "asciidoc.useWorkspaceRoot" = true;
        "asciidoc.wkhtmltopdf.executablePath" = "";

        # General VS Code settings
        "catppuccin.accentColor" = "blue";
        "editor.fontFamily" = "JetBrainsMono Nerd Font";
        "editor.fontSize" = 12;
        "editor.formatOnSave" = true;
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;

        # File associations for AsciiDoc
        "files.associations" = {
          "*.adoc" = "asciidoc";
          "*.asciidoc" = "asciidoc";
          "*.asc" = "asciidoc";
        };

        "npm.fetchOnlinePackageInfo" = false;
        "roo-cline.allowedCommands" = [
          "npm test"
          "npm install"
          "tsc"
          "git log"
          "git diff"
          "git show"
        ];
        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
        "update.mode" = "none";
        "workbench.colorTheme" = "Catppuccin Latte";
        "workbench.enableExperiments" = false;
        "workbench.iconTheme" = "catppuccin-latte";
        "workbench.settings.enableNaturalLanguageSearch" = false;
        "roo-cline.deniedCommands" = [];
      };
    };
  };
}
