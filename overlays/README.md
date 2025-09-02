# Nix Overlays for nix-config

This directory contains modular Nix overlays that extend or customize packages in the nixpkgs ecosystem for local development and testing.

## Structure

```
overlays/
├── default.nix              # Main overlay aggregator
└── vscode-extensions/        # VSCode extension overlays
    ├── default.nix          # VSCode extensions overlay
    └── roo-cline.nix        # Roo Cline extension package
```

## Usage

The overlays are automatically applied in [`flake.nix`](../flake.nix) through:

```nix
nixpkgs.overlays = [
  nur.overlays.default
  (import ./overlays)
];
```

## Adding New Overlays

### 1. Create a new overlay module

Create a new directory under `overlays/` for your overlay category:

```bash
mkdir overlays/your-category
```

### 2. Create the overlay file

```nix
# overlays/your-category/default.nix
final: prev: {
  your-package = final.callPackage ./your-package.nix {};
}
```

### 3. Update the main overlay aggregator

Add your overlay to [`overlays/default.nix`](./default.nix):

```nix
final: prev: {
  # Import all overlay modules
} // (import ./your-category final prev)
// (import ./another-category final prev)
```

## VSCode Extensions Overlay

The [`vscode-extensions`](./vscode-extensions/) overlay provides custom VSCode extensions that aren't available in nixpkgs or need local development versions.

### Available Extensions

- **[`rooveterinaryinc.roo-cline`](./vscode-extensions/roo-cline.nix)**: AI-powered development assistant
  - Fetched from VS Code Marketplace
  - Version: 3.25.13
  - License: Apache 2.0

### Usage in Configuration

The extension is available through the standard `pkgs.vscode-extensions` attribute:

```nix
# home/dan/features/productivity/vscode.nix
programs.vscode = {
  enable = true;
  profiles.default = {
    extensions = with pkgs.vscode-extensions; [
      rooveterinaryinc.roo-cline  # Now provided by overlay
      # ... other extensions
    ];
  };
};
```

## Local Development

### For VSCode Extensions

To use a local development version of an extension:

1. **Update Version and Hash**: Modify the version and sha256 in the extension's `.nix` file
2. **From Local VSIX**: Replace `buildVscodeMarketplaceExtension` with `buildVscodeExtension`:
   ```nix
   vscode-utils.buildVscodeExtension {
     src = ./path/to/extension.vsix;
     # ... other attributes
   }
   ```

## Best Practices

1. **Modular Structure**: Keep related packages in the same overlay module
2. **Version Pinning**: Always specify exact versions for reproducibility
3. **License Information**: Include accurate license information in metadata
4. **Documentation**: Document the purpose and usage of each overlay
5. **Git Tracking**: Ensure overlay files are committed to git for flake evaluation

## Migration from pkgs-dan-testing

This overlay system replaces the previous `pkgs-dan-testing` flake input that was used for the roo-cline extension. Benefits include:

- **Local Development**: No need to maintain a separate nixpkgs fork
- **Modularity**: Easy to add/remove/modify packages independently
- **Reproducibility**: Version-controlled alongside the main configuration
- **Flexibility**: Can easily switch between marketplace and local versions

### Changes Made

1. **Removed flake input**: `nixpkgs-dan-testing` input removed from `flake.nix`
2. **Added overlay**: Local overlay created in `overlays/vscode-extensions/`
3. **Updated configuration**: VSCode configuration now uses `pkgs.vscode-extensions.rooveterinaryinc.roo-cline`

## Testing

To test overlay changes:

```bash
# Check flake evaluation
nix flake check

# Build system configuration (dry-run)
darwin-rebuild build --flake .

# Build specific package
nix build .#pkgs.vscode-extensions.rooveterinaryinc.roo-cline
```

## Troubleshooting

### Common Issues

1. **"Path not tracked by Git"**: Ensure overlay files are added to git:

   ```bash
   git add overlays/
   ```

2. **Infinite recursion**: Check overlay syntax - should be `final: prev: { ... }` not `{...}: final: prev: { ... }`

3. **Extension not found**: Verify the extension is properly exported in the overlay chain

### Hash Updates

When updating extension versions, you may need to update the `sha256` hash:

1. Set hash to `lib.fakeSha256` temporarily
2. Run build to get the correct hash from the error message
3. Update the hash in the `.nix` file
