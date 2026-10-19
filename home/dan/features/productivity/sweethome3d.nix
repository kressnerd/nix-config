{
  config,
  lib,
  pkgs,
  ...
}:
let
  # SweetHome 3D uses Java's GTK look-and-feel. With the desktop theme
  # (adw-gtk3) that look-and-feel resolves Tree.textBackground to the theme's
  # text colour, so every tree row is painted as a solid dark bar and the
  # furniture catalog is unreadable. Adwaita resolves the same colour to the
  # view background. The extra JVM flags turn on font antialiasing, which
  # Swing renders without by default under XWayland.
  sweethome3d = pkgs.sweethome3d.application.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      substituteInPlace $out/bin/sweethome3d \
        --replace-fail "-Dsun.java2d.opengl=true" \
        "-Dsun.java2d.opengl=true -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
      wrapProgram $out/bin/sweethome3d --set GTK_THEME Adwaita
    '';
  });
in
lib.mkMerge [
  {
    home.packages = [ sweethome3d ];
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [ ".eteks" ];
  })
]
