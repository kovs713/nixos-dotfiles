{
  config,
  lib,
  pkgs,
  variant,
  ...
}:
{
  imports = [ ./theme.nix ];

  home.packages = with pkgs; [
    quickshell

    # What the bar shells out to.
    wayland-utils
    libnotify

    # Clipboard
    wl-clipboard
    cliphist

    brightnessctl
    ddcutil
    hyprsunset

    netcat-openbsd
  ];

  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/quickshell/config";

  xdg.configFile."cliphist/config".text = "max-items 10000\n";

  xdg.dataFile."dbus-1/services/org.freedesktop.Notifications.service".text = ''
    [D-BUS Service]
    Name=org.freedesktop.Notifications
    Exec=${pkgs.quickshell}/bin/qs
    SystemdService=quickshell.service
  '';

  home.activation.hyprsunset = ''
    ${pkgs.systemd}/bin/systemctl --user enable hyprsunset.service
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

      ExecStart = "${lib.getExe pkgs.quickshell}";
      Restart = "on-failure";
      RestartSec = 2;
      Slice = "session.slice";

      KillMode = "process";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history watcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      Type = "exec";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${lib.getExe pkgs.cliphist} store";
      Restart = "always";
      RestartSec = 2;
      Slice = "session.slice";

      KillMode = "process";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
