{ config, ... }:
{
  assertions = [
    {
      assertion = config.programs.aerospace.enable;
      message = "aerospace: programs.aerospace.enable must be true — import features/macos/aerospace.nix";
    }
  ];
}
