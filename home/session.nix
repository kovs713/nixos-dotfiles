{ pkgs, ... }:
{
  home.username = "kovs";
  home.homeDirectory = "/home/kovs";

  home.pointerCursor = {
    enable = true;
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    TERMINAL = "foot";

    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "24";

    XDG_DOWNLOAD_DIR = "$HOME/Downloads";
    XDG_DOCUMENTS_DIR = "$HOME/Documents";
    XDG_PICTURES_DIR = "$HOME/Pictures";
    XDG_VIDEOS_DIR = "$HOME/Videos";

    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";

    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    GDK_BACKEND = "wayland";
  };

  programs.home-manager.enable = true;

  programs.foot.enable = true;

  programs.chromium.enable = true;
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    profiles.default = {
      userChrome = builtins.readFile ./themed/zen/userChrome.css;

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # --- flat / square / borderless ---
        "widget.gtk.rounded-bottom-corners.enabled" = false;
        "zen.theme.border-radius" = 0; # also writes --zen-border-radius
        "zen.theme.content-element-separation" = 0; # also sets [zen-no-padding]
        "zen.view.hide-window-controls" = true;
        "zen.view.compact.enable-at-startup" = true;
        "services.sync.engine.spaces" = true;
      };
    };
  };

  xdg.terminal-exec = {
    enable = true;
    settings.default = [
      "foot.desktop"
    ];
  };

  dconf.settings = {
    "org/gnome/nm-applet" = {
      disable-connected-notifications = true;
      disable-disconnected-notifications = true;
      disable-vpn-notifications = true;
      suppress-wireless-networks-available = true;
    };

    "org/blueman/general" = {
      plugin-list = [ "!ConnectionNotifier" ];
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.stateVersion = "26.05";
}
