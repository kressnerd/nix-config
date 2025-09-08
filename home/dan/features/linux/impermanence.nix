{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  home.persistence."/persist/home" = {
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
      #      { directory = ".gnupg"; mode = "0700"; }
      #      { directory = ".ssh"; mode = "0700"; }
    ];
    files = [
      ".bash_history"
    ];
    allowOther = true;
  };
}
