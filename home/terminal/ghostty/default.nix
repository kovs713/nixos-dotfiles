{ config, ... }:
{
  programs.ghostty = {
    enable = true;
    settings.config-file = "${config.xdg.configHome}/ghostty/live.conf";
  };

  xdg.configFile."ghostty/live.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/terminal/ghostty/config";

  xdg.configFile."ghostty/shaders/cursor_sweep.glsl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/terminal/ghostty/shaders/cursor_sweep.glsl";
}
