_: {
  home.persistence."/persist" = {
    directories = [
      ".cache/mozilla"
      ".claude"
      ".mozilla" # Firefox
      ".ssh"
      ".vscode/extensions"
      # Roo Code rules and skills
      ".roo"
      # VSCode
      ".config/Code"
      # yazi history, bookmarks, tab state
      ".local/share/yazi"
      # ownCloud client
      ".config/ownCloud"
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
  };
}
