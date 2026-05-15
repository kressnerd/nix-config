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
  ];
}
