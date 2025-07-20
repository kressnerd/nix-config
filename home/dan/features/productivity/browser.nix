{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;

    profiles = {
      personal = {
        id = 0;
        name = "personal";
        isDefault = false;

        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.tabs.firefox-view" = false;
        };

        search = {
          force = true;
          default = "ddg";

          engines = {
            "Kagi" = {
              urls = [
                {
                  template = "https://kagi.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "https://kagi.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = ["@k"];
            };
          };
        };
      };

      company = {
        id = 1;
        name = "company";
        isDefault = true;

        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";
        };

        search = {
          force = true;
          default = "google";
        };
      };

      client001 = {
        id = 2;
        name = "client001";
        isDefault = false;

        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";
        };

        search = {
          force = true;
          default = "ddg";
        };
      };
    };
  };

  # Create a symlink from LibreWolf to Firefox profiles
  home.activation.linkLibrewolfProfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/Library/Application Support/LibreWolf"
    rm -f "$HOME/Library/Application Support/LibreWolf/profiles.ini"
    ln -sf "$HOME/Library/Application Support/Firefox/profiles.ini" \
           "$HOME/Library/Application Support/LibreWolf/profiles.ini"

    if [ ! -L "$HOME/Library/Application Support/LibreWolf/Profiles" ]; then
      rm -rf "$HOME/Library/Application Support/LibreWolf/Profiles"
      ln -sf "$HOME/Library/Application Support/Firefox/Profiles" \
             "$HOME/Library/Application Support/LibreWolf/Profiles"
    fi
  '';

  # Create a mapping file with sops values
  sops.templates."browser-profile-mapping" = {
    content = ''
      # Browser Profile to Folder Mapping
      personal=${config.sops.placeholder."git/personal/folder"}
      company=${config.sops.placeholder."git/company/folder"}
      client001=${config.sops.placeholder."git/client001/folder"}
    '';
    path = "${config.home.homeDirectory}/.config/browser-profiles.env";
  };

  home.packages = let
    librewolfBin = "${pkgs.librewolf}/bin/librewolf";

    makeProfileLauncher = name: profile:
      pkgs.writeShellScriptBin "lw-${name}" ''
        exec ${librewolfBin} -P "${profile}" "$@"
      '';
  in [
    (makeProfileLauncher "personal" "personal")
    (makeProfileLauncher "company" "company")
    (makeProfileLauncher "client" "client001")
  ];

  programs.zsh.shellAliases = {
    lw = "${pkgs.librewolf}/bin/librewolf";
    lw-profiles = "${pkgs.librewolf}/bin/librewolf -ProfileManager";
  };
}
