{ pkgs, ... }:
{
  imports = [
    ./ghostty
    ./opencode
    ./shell
  ];

  programs.foot.enable = true;
  xdg.terminal-exec = {
    enable = true;
    settings.default = [
      "foot.desktop"
    ];
  };

  programs.btop = {
    enable = true;
    settings.vim_keys = true;

    package = pkgs.symlinkJoin {
      name = "btop-nvidia";
      paths = [ pkgs.btop ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/btop --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
      '';
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global = {
      log_format = "-";
      log_filter = "^$";
    };
  };
}
