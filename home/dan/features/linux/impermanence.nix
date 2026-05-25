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
      # LibreOffice
      ".config/libreoffice"
      # ownCloud client
      ".config/ownCloud"
      # netcup SCP firewall tool (Epic 15a)
      ".config/netcup-scp"
      ".local/share/netcup-scp"
      # yazi history, bookmarks, tab state
      ".local/share/yazi"
      ".local/share/ownCloud"
      # Maestral Dropbox client
      "Dropbox"
      ".config/maestral"
      ".local/share/maestral"
      # gnome-keyring encrypted keyring files
      ".local/share/keyrings"
      # Rootless Podman container images, layers, and volumes
      ".local/share/containers"
      # SweetHome3D
      ".eteks"
      # Signal Desktop messaging state
      ".config/Signal"
      # Threema Desktop messaging state
      ".config/Threema"
      # Screen recordings (wf-recorder output)
      "Videos"
    ];
    files = [
      ".bash_history"
    ];
  };
}
