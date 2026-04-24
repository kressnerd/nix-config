_: {
  home.persistence."/persist" = {
    directories = [
      # yazi history, bookmarks, tab state
      ".local/share/yazi"
      # Rootless Podman container images, layers, and volumes
      ".local/share/containers"
      # Screen recordings (wf-recorder output)
      "Videos"
    ];
  };
}
