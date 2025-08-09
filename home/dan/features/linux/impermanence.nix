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
      ".cache/mesa_shader_cache"
      ".cache/mesa_shader_cache_db"
      ".cache/mozilla"
      ".mozilla" # Firefox
      "Projects"
    ];
    files = [
      ".bash_history"
    ];
    allowOther = true;
  };
}
