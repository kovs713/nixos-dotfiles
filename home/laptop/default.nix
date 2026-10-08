{ pkgs, ... }:
{
  imports = [
    ./hyprland.nix
    ./airpods.nix
  ];

  home.packages = [ pkgs.blueman ];

  dconf.settings = {
    "org/gnome/nm-applet" = {
      disable-connected-notifications = true;
      disable-disconnected-notifications = true;
      disable-vpn-notifications = true;
      suppress-wireless-networks-available = true;
    };

    "org/blueman/general" = {
      plugin-list = [ "!ConnectionNotifier" ];
    };
  };
}
