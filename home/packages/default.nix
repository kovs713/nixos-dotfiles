{
  pkgs,
  inputs,
  system,
  ...
}:
{
  imports = [
    ./dev.nix
  ];

  home.packages = with pkgs; [
    inputs.ayugram-desktop.packages.${system}.default

    # cli
    bitwarden-cli
    fastfetch
    ripgrep
    ffmpeg
    zoxide
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
