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

  # The forgotten-override guard, as on adlerkopf. cupix001 is not deployed yet,
  # so the preflight also fails closed while its private values are still empty.
  programs.fish = {
    enable = true;
    functions.rebuild.body = ''
      set -l value (nix eval --raw ${flake}#nixosConfigurations.cupix001.config.networking.cupix001.publicIPv4 --override-input private ${privateFlake} 2>/dev/null)
      if test -z "$value"
        echo "refusing: the private input supplied no values for cupix001" >&2
        echo "fill ~/dev/PRIVATE/nix-private/cupix001.nix before deploying this host" >&2
        return 1
      end
      sudo nixos-rebuild switch --flake ${flake}#cupix001 --override-input private ${privateFlake} $argv
    '';
  };
}
