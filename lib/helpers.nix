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
