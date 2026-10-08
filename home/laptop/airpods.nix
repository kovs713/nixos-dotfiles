{ lib, pkgs, ... }:

let
  librepods = pkgs.callPackage ../../packages/librepods { };
in
{
  home.packages = [ librepods ];

  systemd.user.services.librepods = {
    Unit = {
      Description = "librepods AirPods daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";

      # Qt logs the BLE advertisement line several times a second.
      Environment = "QT_LOGGING_RULES=openpods.debug=false";

      # --headless builds neither the tray nor the QML engine, for 15 MB less
      # resident memory and no window to reopen later.
      ExecStart = "${lib.getExe librepods} --headless";

      Restart = "on-failure";
      RestartSec = 5;

      # The status file carries the paired device identity and the config directory
      # holds its pairing keys, so nothing the daemon writes is world-readable.
      UMask = "0077";

      # ~/.local/state/librepods is where the daemon publishes status.json.
      StateDirectory = [ "librepods" ];
      StateDirectoryMode = "0700";

      # The magicAccIRK and magicAccEncKey the BLE advertisements are matched by.
      ConfigurationDirectory = [ "AirPodsTrayApp" ];
      ConfigurationDirectoryMode = "0700";

      ProtectSystem = "strict";

      # strict leaves home to ProtectHome, so home needs read-only.
      ProtectHome = "read-only";

      # ProtectHome takes /run/user too, and the control socket has to live there.
      ReadWritePaths = [ "%t" ];

      PrivateTmp = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;

      # BlueZ takes AF_BLUETOOTH, the HCI address-type probe takes AF_NETLINK,
      # everything else is a local socket.
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_BLUETOOTH"
        "AF_NETLINK"
      ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
