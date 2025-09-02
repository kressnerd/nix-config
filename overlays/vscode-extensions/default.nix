# VSCode Extensions Overlay
# Provides custom and local VSCode extensions that aren't available in nixpkgs
# or need local development versions
final: prev: {
  vscode-extensions =
    prev.vscode-extensions
    // {
      rooveterinaryinc =
        prev.vscode-extensions.rooveterinaryinc or {}
        // {
          roo-cline = final.callPackage ./roo-cline.nix {};
        };
    };
}
