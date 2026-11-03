{ makiPackage, ... }:
{
  # Maki — terminal coding agent written in Rust. The package comes from the
  # repository's own overlay (`overlays/maki`), which pins an upstream prebuilt
  # release per platform by version and checksum; nixpkgs carries no package.
  #
  # Config, auth, sessions and logs follow the XDG layout under
  # `~/.config/maki`, `~/.local/share/maki`, `~/.local/state/maki`, and
  # `~/.local/logs/maki`. Maki reads the repository's `AGENTS.md` and the
  # givn-generated `.maki/skills/` without any user-level configuration.
  home.packages = [ makiPackage ];
}
