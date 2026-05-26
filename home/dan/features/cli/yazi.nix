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
        # Adapt legacy entry(state, args) to v0.4.0+ entry(self, job) API.
        # call_method("entry", job) now passes plugin-table as self and job={args=…}
        # as the second arg; extract job.args so the body's args[1]/args[2]/… still work.
        ${pkgs.gnused}/bin/sed -i \
          's/^local function entry(state, args)$/local function entry(state, job)\n  local args = job.args/' \
          $out/main.lua
        ${pkgs.gnused}/bin/sed -i 's/ya\.app_emit/ya.emit/g' $out/main.lua
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
          # v25.2.7+: positional args replace --args=; --mode=sync replaces --sync
          run = "plugin --mode=sync dual-pane toggle";
          desc = "Dual-pane: toggle";
        }
        {
          on = [
            "b"
            "b"
          ];
          run = "plugin --mode=sync dual-pane toggle_zoom";
          desc = "Dual-pane: toggle zoom";
        }
        {
          on = [ "<Tab>" ];
          run = "plugin --mode=sync dual-pane next_pane";
          desc = "Dual-pane: switch pane";
        }
        {
          on = [ "[" ];
          # Use -- inside the quoted arg-string so --relative stays positional (args[3])
          run = "plugin --mode=sync dual-pane 'tab_switch -1 -- --relative'";
          desc = "Dual-pane: prev tab";
        }
        {
          on = [ "]" ];
          run = "plugin --mode=sync dual-pane 'tab_switch 1 -- --relative'";
          desc = "Dual-pane: next tab";
        }
        {
          on = [ "1" ];
          run = "plugin --mode=sync dual-pane 'tab_switch 0'";
          desc = "Switch to tab 1";
        }
        {
          on = [ "2" ];
          run = "plugin --mode=sync dual-pane 'tab_switch 1'";
          desc = "Switch to tab 2";
        }
        {
          on = [ "3" ];
          run = "plugin --mode=sync dual-pane 'tab_switch 2'";
          desc = "Switch to tab 3";
        }
        {
          on = [ "<F5>" ];
          # Use -- so --follow reaches args[2] as a positional string
          run = "plugin --mode=sync dual-pane 'copy_files -- --follow'";
          desc = "Dual-pane: copy to other pane";
        }
        {
          on = [ "<F6>" ];
          run = "plugin --mode=sync dual-pane 'move_files -- --follow'";
          desc = "Dual-pane: move to other pane";
        }
      ];
    };
  };

  stylix.targets.yazi.enable = true;
}
