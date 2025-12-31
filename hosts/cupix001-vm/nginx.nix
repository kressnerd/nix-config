# Simplified nginx for VM testing (self-signed certs)
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Nginx reverse proxy
  services.nginx = {
    enable = true;

    # Recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Security headers
    commonHttpConfig = ''
      # Security headers
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;

      # Logging
      access_log /var/log/nginx/access.log;
      error_log /var/log/nginx/error.log;

      # Rate limiting
      limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
      limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
    '';

    # Virtual hosts (VM testing without ACME)
    virtualHosts = {
      # Main domain - default catch-all
      "cupix001-vm.local" = {
        default = true;
        locations."/" = {
          return = "200 'VM Test Server Running'";
          extraConfig = ''
            add_header Content-Type text/plain;
          '';
        };
      };

      # Headscale (HTTP only for VM testing)
      "headscale.local" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
          extraConfig = ''
            limit_req zone=api burst=20 nodelay;

            # Headscale-specific headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Timeouts for long-polling
            proxy_read_timeout 300s;
            proxy_send_timeout 300s;
          '';
        };

        # Metrics endpoint (restrict access)
        locations."/metrics" = {
          proxyPass = "http://127.0.0.1:9090";
          extraConfig = ''
            allow 127.0.0.1;
            deny all;
          '';
        };
      };
    };
  };
}
