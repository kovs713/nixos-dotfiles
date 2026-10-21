{
  config,
  lib,
  ...
}:
let
  colors = config.lib.stylix.colors;
in
{
  programs.tmux = {
    enable = true;

    extraConfig = lib.mkAfter ''
      set -g @tmux_accent      "#${colors.base0D}"
      set -g @tmux_accent_text "#${colors.base00}"
      set -g @tmux_muted       "#${colors.base03}"

      source-file "${config.xdg.configHome}/tmux/live.conf"
    '';
  };

  xdg.configFile."tmux/live.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/themed/tmux.conf";
}
