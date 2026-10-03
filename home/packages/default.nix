{ pkgs, ... }:
{
  imports = [
    ./dev.nix
  ];

  home.packages = with pkgs; [
    ayugram-desktop

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
  ];
}
