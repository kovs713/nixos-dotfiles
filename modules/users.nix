{ pkgs, ... }:
{
  services.getty.autologinUser = "kovs";

  programs.fish.enable = true;
  programs.fish.loginShellInit = ''
    if status is-login; and test -z "$WAYLAND_DISPLAY"; and test "$(tty)" = "/dev/tty1"
        exec start-hyprland
    end
  '';

  users.users.kovs = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "render"
      "input"
    ];
    initialPassword = " ";
    shell = pkgs.fish;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      glibc
      zlib
      openssl
      icu
      libffi
    ];
  };
}
