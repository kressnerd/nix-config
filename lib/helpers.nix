{
  mkPkgsUnstable =
    {
      nixpkgs-unstable,
      system,
    }:
    import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

  # A program on a device may rewrite a file the home profile renders (the
  # browser rewrites its profile registry and search state). Home Manager refuses
  # to replace a foreign file and aborts the activation, so this is wired as
  # `home-manager.backupCommand`: Home Manager runs it with the conflicting path
  # as its final argument, and it renames the file to the first free
  # `<name>.<n>` beside the rendered one — every rewrite displaced, nothing
  # deleted. See the change `managed-file-displacement`.
  mkManagedFileDisplacement =
    pkgs:
    pkgs.writeShellScript "hm-displace-managed-file" ''
      set -euo pipefail

      target="$1"
      n=1
      while [ -e "$target.$n" ]; do
        n=$((n + 1))
      done
      mv -- "$target" "$target.$n"
    '';

  mkFirefoxExtensions =
    { addons }:
    {
      common = with addons; [
        ublock-origin
        keepassxc-browser
        consent-o-matic
      ];

      dev = with addons; [
        refined-github
        octotree
        wappalyzer
      ];

      privacy = with addons; [
        privacy-badger
        decentraleyes
        clearurls
        noscript
        temporary-containers
      ];

      productivity = with addons; [
        tridactyl
        tree-style-tab
        languagetool
        single-file
      ];

      convenience = with addons; [
        sponsorblock
        return-youtube-dislikes
        youtube-shorts-block
        reddit-enhancement-suite
        old-reddit-redirect
      ];
    };
}
