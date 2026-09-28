{ pkgs, variant, ... }:
let
  quickshellConfig = pkgs.runCommand "quickshell-config" { } ''
    mkdir -p "$out"
    cp -r ${./config}/. "$out/"
    chmod -R u+w "$out"
    mkdir -p "$out/assets"
    chmod -R u-w "$out"
  '';
in
{
  home.packages = with pkgs; [
    quickshell

    # Wayland Utilities
    wayland-utils

    # Clipboard
    wl-clipboard
    cliphist
    wtype

    # Hardware / Media Controls
    brightnessctl
    libnotify
    blueman

    # Screen colour temperature.
    hyprsunset
  ];

  xdg.configFile."quickshell".source = quickshellConfig;

  xdg.dataFile."dbus-1/services/org.freedesktop.Notifications.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.Notifications
    Exec=${pkgs.quickshell}/bin/qs
    SystemdService=quickshell.service
  '';

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

  home.activation.hyprsunset = ''
    systemctl --user enable hyprsunset.service >/dev/null 2>&1 || true
  '';

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell and notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "dbus.socket"
      ];
      Requires = [ "dbus.socket" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
      StartLimitBurst = 8;
      StartLimitIntervalSec = 60;
    };

    Service = {
      Type = "exec";

      Environment = [
        "QS_ICON_THEME=Adwaita"
        "SHELL_THEME=${variant}"
        "XDG_SESSION_TYPE=wayland"
      ];

      ExecStart = "${pkgs.quickshell}/bin/qs";
      Restart = "on-failure";
      RestartSec = 2;
      Slice = "session.slice";

      KillMode = "process";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
