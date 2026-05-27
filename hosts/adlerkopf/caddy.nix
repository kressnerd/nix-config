{ pkgs, ... }:
{
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/netcup@v1.0.0" ];
      hash = "sha256-U6JeuInrNLrmxDAPcTdY7kHkxlKBuM39mDVxIoJmMHw=";
    };
  };
}
