{
  config,
  pkgs,
  lib,
  ...
}: {
  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8080;

    settings = {
      server_url = "https://headscale.kressner.cloud";

      # Listen addr for metrics
      metrics_listen_addr = "127.0.0.1:9090";

      # gRPC settings
      grpc_listen_addr = "127.0.0.1:50443";
      grpc_allow_insecure = false;

      # Noise protocol private key
      noise = {
        private_key_path = config.sops.secrets."headscale/noise-private-key".path;
      };

      # IP prefix configuration
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };

      # DERP configuration
      derp = {
        server = {
          enabled = true;
          region_id = 999;
          region_code = "cupix";
          region_name = "Cupix001";
          stun_listen_addr = "0.0.0.0:3478";
        };

        # Use built-in DERP server
        urls = [];
        paths = [];
        auto_update_enabled = false;
      };

      # Database
      database = {
        type = "sqlite";
        sqlite = {
          path = "/var/lib/headscale/db.sqlite";
        };
      };

      # DNS configuration
      dns = {
        override_local_dns = true;
        magic_dns = true;
        base_domain = "tail.kressner.cloud";
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };

      # ACL policy file
      policy = {
        path = "/var/lib/headscale/acl.json";
      };

      # Log settings
      log = {
        format = "text";
        level = "info";
      };

      # Disable updates check
      disable_check_updates = true;

      # Ephemeral node configuration
      ephemeral_node_inactivity_timeout = "30m";
    };
  };

  # Create ACL policy file
  systemd.tmpfiles.rules = [
    "f /var/lib/headscale/acl.json 0640 headscale headscale - ${builtins.toJSON {
      acls = [
        {
          action = "accept";
          src = ["*"];
          dst = ["*:*"];
        }
      ];
      ssh = [
        {
          action = "accept";
          src = ["*"];
          dst = ["*"];
          users = ["*"];
        }
      ];
    }}"
  ];
}
