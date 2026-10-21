{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  home.packages = with pkgs; [
    hyprcursor

    hyprpicker
    hyprshot
    satty
    gpu-screen-recorder

    blueman
    wireplumber
    playerctl
  ];

  xdg.configFile."hypr/theme.lua" = {
    text = ''
      hl.config({misc = {background_color = "rgb(${config.lib.stylix.colors.base00})", disable_hyprland_logo = true, disable_splash_rendering = true}})
    '';
    onChange = ''
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        ${lib.getExe' osConfig.programs.hyprland.package "hyprctl"} reload config-only
      fi
    '';
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = osConfig.programs.hyprland.package;
    xwayland.enable = true;

    portalPackage = null;

    systemd = {
      enable = false;
      variables = [ "--all" ];
    };
  };

  xdg.configFile."hypr/hyprland.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/hyprland.lua";
}
