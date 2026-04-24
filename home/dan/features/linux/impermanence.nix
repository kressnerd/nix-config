_: {
  home.persistence."/persist" = {
    directories = [
      ".vscode/extensions"
      # Roo Code rules and skills
      ".roo"
      # VSCode
      ".config/Code"
      # yazi history, bookmarks, tab state
      ".local/share/yazi"
      # Rootless Podman container images, layers, and volumes
      ".local/share/containers"
      # Signal Desktop messaging state
      ".config/Signal"
      # Threema Desktop messaging state
      ".config/Threema"
      # Screen recordings (wf-recorder output)
      "Videos"
    ];
  };
}
