{ config, ... }:
{
  assertions = [
    {
      assertion = config.programs.aerospace.enable;
      message = "aerospace: programs.aerospace.enable must be true — import features/macos/aerospace.nix";
    }
    {
      assertion =
        let
          settings = config.programs.aerospace.userSettings;
        in
        builtins.hasAttr "workspace-to-monitor-force-assignment" settings
        && settings."workspace-to-monitor-force-assignment"."1" == "main";
      message = "aerospace: workspace 1 must be force-assigned to main monitor";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-h" bindings
        && builtins.match ".*all-monitors-outer-frame.*" bindings."alt-h" != null;
      message = "aerospace: alt-h focus must use --boundaries all-monitors-outer-frame for cross-monitor navigation";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-tab" bindings && bindings."alt-tab" == "focus-monitor --wrap-around next";
      message = "aerospace: alt-tab must be bound to focus-monitor --wrap-around next";
    }
  ];
}
