_:
let
  flake = "/home/dan/dev/PRIVATE/nix-config";
  privateFlake = "git+file:///home/dan/dev/PRIVATE/nix-private";
in
{
  imports = [
    ./global/default.nix
  ];

  home = {
    username = "dan";
    homeDirectory = "/home/dan";
  };

  # The forgotten-override guard: evaluate the host with the private input and
  # refuse to deploy when it supplied no values, so a placeholder address never
  # reaches the running system.
  programs.fish = {
    enable = true;
    functions.rebuild.body = ''
      set -l value (nix eval --raw ${flake}#nixosConfigurations.adlerkopf.config.networking.adlerkopf.lanIPv4 --override-input private ${privateFlake} 2>/dev/null)
      if test -z "$value"; or string match -q '192.0.2.*' -- $value
        echo "refusing: the private input supplied no values (got '$value')" >&2
        echo "expected --override-input private ${privateFlake} to supply the real address" >&2
        return 1
      end
      sudo nixos-rebuild switch --flake ${flake}#adlerkopf --override-input private ${privateFlake} $argv
    '';
  };
}
