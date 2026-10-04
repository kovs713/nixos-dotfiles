{ pkgs, lib, ... }:
{
  imports = [
    ./dev.nix
  ];

  home.packages =
    with pkgs;
    [
      ayugram-desktop
      vial

      # cli
      bitwarden-cli
      ripgrep
      ffmpeg
      zoxide
      nitch
      unzip
      btop
      cloc
      curl
      tree
      wget
      fd

      # files manager, videos, images
      nautilus
      mpv
      imv
    ]
    # shell scripts from ./scripts, installed by name
    ++ (map (script: pkgs.writeShellScriptBin script (builtins.readFile "${../scripts}/${script}")) (
      lib.attrNames (builtins.readDir ../scripts)
    ));
}
