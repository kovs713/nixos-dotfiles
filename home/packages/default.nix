{ pkgs, lib, ... }:
let
  photocraft = pkgs.callPackage ../../packages/photocraft { };
in
{
  imports = [
    ./dev.nix
  ];

  home.packages =
    with pkgs;
    [
      ayugram-desktop
      photocraft
      obsidian
      dstask
      anki
      kid3
      vial

      # cli
      bitwarden-cli
      ripgrep
      ffmpeg
      yt-dlp
      nitch
      unzip
      cloc
      curl
      tree
      wget
      bat
      fd

      # files manager, videos, images
      nautilus
      chafa
      imagemagick # snacks.image needs magick/identify
      mpv
      imv
    ]
    # shell scripts from ./scripts, installed by name
    ++ (map (script: pkgs.writeShellScriptBin script (builtins.readFile "${../scripts}/${script}")) (
      lib.attrNames (builtins.readDir ../scripts)
    ));
}
