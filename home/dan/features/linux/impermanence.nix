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
      ".local/share/ownCloud"
      # gnome-keyring encrypted keyring files
      ".local/share/keyrings"
      # SweetHome3D
      ".eteks"
    ];
    files = [
      ".bash_history"
    ];
  };
}
