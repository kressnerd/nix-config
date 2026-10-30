{ pkgs, ... }:
{
  home.packages = [ pkgs.swayosd ];

  # SwayOSD has no Stylix target; keep its overlay on the One Light palette.
  # Selectors match swayosd 0.3.2's default stylesheet.
  xdg.configFile."swayosd/style.css".text = ''
    window#osd {
      border-radius: 12px;
      border: 2px solid #e5e5e6;
      background: #fafafa;
    }

    window#osd #container {
      margin: 14px 18px;
      min-width: 220px;
    }

    window#osd image,
    window#osd label {
      color: #383a42;
    }

    window#osd progressbar:disabled,
    window#osd image:disabled {
      opacity: 0.5;
    }

    window#osd progressbar,
    window#osd trough {
      min-height: 6px;
      border-radius: 999px;
      border: none;
      background: #e5e5e6;
    }

    window#osd progress {
      min-height: 6px;
      border-radius: 999px;
      background: #4078f2;
    }
  '';
}
