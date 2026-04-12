# tests/assertions/thiniel-impermanence-invariants.nix
# Thiniel-specific impermanence assertions — enforced at evaluation time via nix flake check
# Characterizes environment.persistence."/persist/system" from hosts/thiniel/default.nix
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    # The impermanence module coerces string paths to attrsets with a `directory`
    # or `file` field — use builtins.any rather than builtins.elem.
    assertions =
      let
        persistSystem = config.environment.persistence."/persist/system";
        hasDir = path: builtins.any (d: d.directory == path) persistSystem.directories;
        hasFile = path: builtins.any (f: f.file == path) persistSystem.files;

        # HM persistence directories may be plain strings or attrsets with `directory`.
        hmPersistDirs = config.home-manager.users.dan.home.persistence."/persist".directories;
        hmHasDir =
          path:
          builtins.any (
            d: if builtins.isString d then d == path else (d.directory or "") == path
          ) hmPersistDirs;
      in
      [
        {
          assertion = hasDir "/var/log";
          message = "Thiniel invariant violated: /var/log must be in system persistence (logs must survive reboot)";
        }
        {
          assertion = hasDir "/var/lib/nixos";
          message = "Thiniel invariant violated: /var/lib/nixos must be in system persistence (NixOS state)";
        }
        {
          assertion = hasDir "/etc/NetworkManager/system-connections";
          message = "Thiniel invariant violated: /etc/NetworkManager/system-connections must be in system persistence (WiFi configs)";
        }
        {
          assertion = hasFile "/var/lib/sops-nix/key.txt";
          message = "Thiniel invariant violated: /var/lib/sops-nix/key.txt must be in system persistence (SOPS decryption key)";
        }
        {
          assertion = hasFile "/etc/machine-id";
          message = "Thiniel invariant violated: /etc/machine-id must be in system persistence (stable machine identity)";
        }
        {
          assertion = !(hmHasDir ".config/keepassxc");
          message = "Thiniel invariant violated: .config/keepassxc must not be in HM persistence — HM manages keepassxc.ini declaratively";
        }
        # VS Code / Roo Code persistence
        {
          assertion = hmHasDir ".config/Code";
          message = "Thiniel invariant violated: .config/Code must be in HM persistence (VS Code user data)";
        }
        {
          assertion = hmHasDir ".vscode/extensions";
          message = "Thiniel invariant violated: .vscode/extensions must be in HM persistence (VS Code extensions)";
        }
        {
          assertion = hmHasDir ".roo";
          message = "Thiniel invariant violated: .roo must be in HM persistence (Roo Code rules and skills)";
        }
        {
          assertion = hmHasDir ".local/share/keyrings";
          message = "Thiniel invariant violated: .local/share/keyrings must be in HM persistence (gnome-keyring for VS Code credential storage)";
        }
        # Podman container data persistence
        {
          assertion = hasDir "/var/lib/containers";
          message = "thiniel: /var/lib/containers must be persisted for Podman container data";
        }
        {
          assertion = hmHasDir ".local/share/containers";
          message = "thiniel: .local/share/containers must be persisted for rootless Podman data";
        }
        {
          assertion = hasDir "/var/lib/bluetooth";
          message = "thiniel: /var/lib/bluetooth must be persisted for bluetooth pairings";
        }
      ];
  };
}
