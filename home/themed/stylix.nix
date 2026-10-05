{
  pkgs,
  inputs,
  system,
  variant,
  ...
}:
let
  scheme = import ./schemes/${variant}.nix;

  polarity =
    {
      black = "dark";
      white = "light";
    }
    .${variant};
in
{
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix = {
    enable = true;
    overlays.enable = false;

    base16Scheme = scheme;

    inherit polarity;

    fonts = {
      sansSerif = {
        package = inputs.apple-fonts.packages.${system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };
      serif = {
        package = pkgs.merriweather;
        name = "Merriweather";
      };
      monospace = {
        package = pkgs.nerd-fonts.caskaydia-mono;
        name = "CaskaydiaMono Nerd Font";
      };
      emoji = {
        package = pkgs.twitter-color-emoji;
        name = "Twitter Color Emoji";
      };
      sizes = {
        terminal = 20;
        applications = 12;
        desktop = 12;
        popups = 12;
      };
    };

    targets = {
      font-packages.enable = true;
      fontconfig.enable = true;

      foot.enable = true;
      ghostty.enable = true;

      zen-browser = {
        enable = true;
        profileNames = [ "default" ];
        enableCss = false;
      };
      anki.enable = true;
      btop.enable = true;
      mpv.enable = true;
      starship.enable = true;

      opencode.enable = false;
      nixvim.enable = false;
      # Zen prioritize gnome shell themes over kvantum
      gnome.enable = false;
    };
  };

  programs.zen-browser.profiles.default.settings."layout.css.devPixelsPerPx" =
    (import ../../display-scale.nix).scale;

  dconf.settings."org/gnome/desktop/interface" = {
    icon-theme = "Adwaita";
    text-scaling-factor = (import ../../display-scale.nix).scale;
    color-scheme = if polarity == "dark" then "prefer-dark" else "prefer-light";
  };

  home.packages = with pkgs; [
    adwaita-icon-theme
    kdePackages.qt6ct
    libsForQt5.qt5ct
    glib.bin
  ];
}
