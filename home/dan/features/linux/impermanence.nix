{
  config,
  inputs,
  ...
}: {
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
      ".config/sops/age"
    ];
    files = [
      ".bash_history"
    ];
  };
}
