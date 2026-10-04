{ ... }:
{
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "zen-beta";

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
    GTK_USE_PORTAL = "1";

    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    randomizedDelaySec = "45min";
    options = "--delete-older-than 7d";
  };

  nix.settings = {
    auto-optimise-store = true;

    substituters = [
      "https://cache.nixos.org/"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # NixOS не даёт uaccess обычным HID-устройствам — без этого vial/qmk не видят /dev/hidraw*
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", GROUP="input", MODE="0660"
  '';

  security.sudo.extraConfig = ''
    Cmnd_Alias X_ROUTINE = \
      /run/current-system/sw/bin/nixos-rebuild switch, \
      /run/current-system/sw/bin/nixos-rebuild switch *, \
      /run/current-system/sw/bin/nixos-rebuild test, \
      /run/current-system/sw/bin/nixos-rebuild test *, \
      /run/current-system/sw/bin/nix store gc, \
      /run/current-system/sw/bin/nix store gc *, \
      /run/current-system/sw/bin/nix store optimise, \
      /run/current-system/sw/bin/nix store optimise *, \
      /run/current-system/sw/bin/nix store verify, \
      /run/current-system/sw/bin/nix store verify *

    kovs ALL=(root) NOPASSWD: X_ROUTINE
  '';

  system.stateVersion = "26.05";
}
