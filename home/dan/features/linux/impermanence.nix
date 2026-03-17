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
      ".mozilla" # Firefox
      ".ssh"
      "dev"
      "Projects"
      ".config/sops/age"
      # KeepassXC
      ".config/keepassxc"
      # ownCloud client
      ".config/ownCloud"
      ".local/share/ownCloud"
      # SweetHome3D
      ".eteks"
    ];
    files = [
      ".bash_history"
    ];
  };
}
