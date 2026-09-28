{ pkgs, ... }:
{
  home.username = "kovs";
  home.homeDirectory = "/home/kovs";

  home.pointerCursor = {
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
  programs.ghostty.enable = true;

  programs.chromium.enable = true;
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  xdg.terminal-exec = {
    enable = true;
    settings.default = [
      "foot.desktop"
    ];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.stateVersion = "26.05";
}
