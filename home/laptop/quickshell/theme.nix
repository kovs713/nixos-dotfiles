{ config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  xdg.configFile."shell/theme.json".text = builtins.toJSON {
    mode = config.stylix.polarity;

    colors = {
      background = colors.base00;
      backgroundDark = colors.base01;
      surface = colors.base01;
      surfaceHover = colors.base02;
      border = colors.base02;
      borderFocus = colors.base0D;
      separator = colors.base02;
      accent = colors.base0D;
      accentHover = colors.base0D;
      accentActive = colors.base07;
      accentMuted = colors.base03;
      accentForeground = colors.base00;
      text = colors.base05;
      textSecondary = colors.base04;
      textMuted = colors.base03;
      success = colors.base0B;
      warning = colors.base0A;
      error = colors.base08;
      info = colors.base0C;
    };

    fonts = {
      interface = config.stylix.fonts.sansSerif.name;
      terminal = config.stylix.fonts.monospace.name;
      emoji = config.stylix.fonts.emoji.name;
    };
  };
}
