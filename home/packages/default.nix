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
      vial
      photocraft

      # cli
      bitwarden-cli
      ripgrep
      ffmpeg
      nitch
      unzip
      btop
      cloc
      curl
      tree
      yaak
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
