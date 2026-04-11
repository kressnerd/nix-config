_: {
  home.persistence."/persist" = {
    directories = [
      #      ".cache/bat"
      #      ".cache/dconf"
      #      ".cache/fontconfig"
      ".cache/mesa_shader_cache"
      ".cache/mesa_shader_cache_db"
      #     ".cargo"
      ".cache/mozilla"
      ".claude"
      ".mozilla" # Firefox
      ".ssh"
      ".vscode/extensions"
      # Roo Code rules and skills
      ".roo"
      "dev"
      "Projects"
      ".config/sops/age"
      # VSCode
      ".config/Code"
      # ownCloud client
      ".config/ownCloud"
      # netcup SCP firewall tool (Epic 15a)
      ".config/netcup-scp"
      ".local/share/netcup-scp"
      ".local/share/ownCloud"
      # gnome-keyring encrypted keyring files
      ".local/share/keyrings"
      # Rootless Podman container images, layers, and volumes
      ".local/share/containers"
      # SweetHome3D
      ".eteks"
    ];
    files = [
      ".bash_history"
    ];
  };
}
