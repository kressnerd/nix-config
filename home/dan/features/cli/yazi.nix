{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    plugins."dual-pane" =
      let
        src = pkgs.fetchFromGitHub {
          owner = "dawsers";
          repo = "dual-pane.yazi";
          rev = "c2fed127035a294d35d3328c33f25014761dcea2";
          hash = "sha256-R/TlCPfo36+cofQBU488Zl81PoRbhhOvFzT5zHYAP4Y=";
        };
      in
      pkgs.runCommand "dual-pane-yazi" { } ''
        mkdir -p $out
        cp -r ${src}/. $out/
        chmod -R u+w $out
        mv $out/init.lua $out/main.lua
      '';

    initLua = ''
      require("dual-pane"):setup()
    '';

    keymap = {
      mgr.prepend_keymap = [
        {
          on = [
            "b"
            "t"
          ];
          run = "plugin --sync dual-pane --args=toggle";
          desc = "Dual-pane: toggle";
        }
        {
          on = [
            "b"
            "b"
          ];
          run = "plugin --sync dual-pane --args=toggle_zoom";
          desc = "Dual-pane: toggle zoom";
        }
        {
          on = [ "<Tab>" ];
          run = "plugin --sync dual-pane --args=next_pane";
          desc = "Dual-pane: switch pane";
        }
        {
          on = [ "[" ];
          run = "plugin --sync dual-pane --args='tab_switch -1 --relative'";
          desc = "Dual-pane: prev tab";
        }
        {
          on = [ "]" ];
          run = "plugin --sync dual-pane --args='tab_switch 1 --relative'";
          desc = "Dual-pane: next tab";
        }
        {
          on = [ "1" ];
          run = "plugin --sync dual-pane --args='tab_switch 0'";
          desc = "Switch to tab 1";
        }
        {
          on = [ "2" ];
          run = "plugin --sync dual-pane --args='tab_switch 1'";
          desc = "Switch to tab 2";
        }
        {
          on = [ "3" ];
          run = "plugin --sync dual-pane --args='tab_switch 2'";
          desc = "Switch to tab 3";
        }
        {
          on = [ "<F5>" ];
          run = "plugin --sync dual-pane --args='copy_files --follow'";
          desc = "Dual-pane: copy to other pane";
        }
        {
          on = [ "<F6>" ];
          run = "plugin --sync dual-pane --args='move_files --follow'";
          desc = "Dual-pane: move to other pane";
        }
      ];
    };
  };

  stylix.targets.yazi.enable = true;
}
