{
  pkgs,
  inputs,
  system,
  ...
}:
let
  displayScale = (import ../display-scale.nix).scale;
in
{
  hardware.graphics.enable = true;

  programs.throne = {
    enable = true;
    tunMode.enable = true;
  };

  programs.dconf = {
    enable = true;
  };

  environment.sessionVariables.GSETTINGS_SCHEMA_DIR = pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas;
  environment.sessionVariables.QT_SCALE_FACTOR = builtins.toJSON displayScale;

  programs.amnezia-vpn.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };

  time.timeZone = "Asia/Tbilisi";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-gstreamer
      obs-vkcapture
    ];
  };

  # no global xkb caps:escape: it would also turn the corne's capslock into esc.
  # Instead keyd remaps capslock -> esc per device, corne (4653:0004) excluded, so
  # the split keeps a real capslock anywhere while every other board (laptop builtin
  # included) gains caps-as-esc.
  services.keyd = {
    enable = true;
    keyboards.caps = {
      ids = [
        "*"
        "-4653:0004"
      ];
      settings.main = {
        raw_modes = "no";
        capslock = "esc";
      };
    };
  };

  # keyd subsumes the physical keyboard, so libinput would take it for an external
  # one and disable-while-typing would stop working on the touchpad.
  services.libinput.enable = true;
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd*keyboard
    AttrKeyboardIntegration=internal
  '';

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    wlr.enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland
    ];

    config = {
      common.default = [
        "gtk"
      ];
      hyprland.default = [
        "gtk"
        "hyprland"
        "wlr"
      ];
    };
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  environment.systemPackages = with pkgs; [
    xdg-utils
  ];
}
