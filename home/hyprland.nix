{
  config,
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  lua = lib.generators.mkLuaInline;
  mod = "SUPER";

  bind = keys: disp: {
    _args = [
      keys
      (lua disp)
    ];
  };
  bindRepeat = keys: disp: {
    _args = [
      keys
      (lua disp)
      (lua "{ repeating = true }")
    ];
  };
  exec = cmd: "hl.dsp.exec_cmd([[${cmd}]])";

  moveWorkspace = workspace: ''hl.dsp.window.move({ workspace = "${workspace}"})'';
  focusWorkspace = workspace: ''hl.dsp.focus({workspace = "${workspace}"})'';
  focusDirection = direction: ''hl.dsp.focus({direction = "${direction}"})'';

  wallpaper = config.lib.stylix.pixel "base00";
in
{
  home.packages = with pkgs; [
    awww
    hyprcursor

    hyprpicker
    hyprshot
    satty
    gpu-screen-recorder

    blueman
    wireplumber
  ];

  systemd.user.services = {
    awww = {
      Unit.Description = "awww wallpaper daemon";
      Service = {
        ExecStart = "${lib.getExe pkgs.awww}-daemon";
        Restart = "on-failure";

        ExecStartPost = "${lib.getExe pkgs.bash} -c 'for _ in {1..10}; do ${lib.getExe pkgs.awww} img --transition-type fade --transition-duration 0.2 ${wallpaper} >/dev/null 2>&1; sleep 0.4; ${lib.getExe pkgs.awww} query 2>/dev/null | grep -qF ${wallpaper} && break; done || echo \"awww: ${wallpaper} did not stick\" >&2'";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    xwayland.enable = true;

    portalPackage = null;

    systemd = {
      enable = false;
      variables = [ "--all" ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "";
        mode = "highrr";
        position = "auto";
        scale = "1";
      }
    ];

    layer_rule = [
      {
        name = "gtk-layer-shell-olay";
        match = {
          namespace = "^(olay-overlay)$";
        };
        screen_share_mode = "omit";
        blur = true;
      }
    ];

    bind = [
      (bind "${mod} + Q" (exec "ghostty"))
      (bind "${mod} + C" "hl.dsp.window.close()")
      (bind "${mod} + F" ''hl.dsp.window.float({ action = "toggle" })'')
      (bind "${mod} + X" (exec "voxtype record toggle"))
      (bind "${mod} + B" (exec "qs ipc call bar toggleAutoReveal"))
      (bind "${mod} + V" (exec "qs ipc call clipboard toggle"))
      (bind "${mod} + N" (exec "qs ipc call notes toggle"))
      (bind "${mod} + SHIFT + N" (exec "qs ipc call nightlight toggle"))
      (bind "${mod} + CTRL + E" (exec "qs ipc call emoji toggle"))
      (bind "${mod} + SPACE" (exec "qs ipc call launcher toggle"))

      (bind "ALT + Print" (exec "shot pick"))
      (bind "Print" (exec "shot clipboard"))
      (bind "${mod} + Print" (exec "shot annotate"))
      (bind "CTRL + Print" (exec "screenrec av"))
      (bind "CTRL + ALT + Print" (exec "screenrec audio"))

      (bind "${mod} + mouse:272" "hl.dsp.window.drag()")
      (bind "${mod} + mouse:273" "hl.dsp.window.resize()")

      (bind "F7" (exec "test -r /tmp/olay-overlay.pid && kill -USR1 \"$(cat /tmp/olay-overlay.pid)\""))
      (bind "F8" (exec "test -r /tmp/olay-overlay.pid && kill -USR2 \"$(cat /tmp/olay-overlay.pid)\""))

      (bind "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      (bindRepeat "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
      (bindRepeat "XF86AudioLowerVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"))
      (bindRepeat "XF86MonBrightnessUp" (exec "backlight up"))
      (bindRepeat "XF86MonBrightnessDown" (exec "backlight down"))

      # Workspaces
      (bind "${mod} + 1" (focusWorkspace "1"))
      (bind "${mod} + 2" (focusWorkspace "2"))
      (bind "${mod} + 3" (focusWorkspace "3"))
      (bind "${mod} + 4" (focusWorkspace "4"))
      (bind "${mod} + 5" (focusWorkspace "5"))

      (bind "${mod} + SHIFT + 1" (moveWorkspace "1"))
      (bind "${mod} + SHIFT + 2" (moveWorkspace "2"))
      (bind "${mod} + SHIFT + 3" (moveWorkspace "3"))
      (bind "${mod} + SHIFT + 4" (moveWorkspace "4"))
      (bind "${mod} + SHIFT + 5" (moveWorkspace "5"))

      (bind "${mod} + h" (focusDirection "l"))
      (bind "${mod} + j" (focusDirection "d"))
      (bind "${mod} + k" (focusDirection "u"))
      (bind "${mod} + l" (focusDirection "r"))
    ];

    config = {
      cursor.no_hardware_cursors = 1;

      general = {
        gaps_in = 0;
        gaps_out = 0;

        border_size = 2;

        layout = "scrolling";
      };

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_space_toggle";
        repeat_rate = 25;
        repeat_delay = 500;
      };

      decoration = {
        rounding = 0;
        shadow.enabled = false;
        blur.enabled = false;
      };
      animations.enabled = false;
    };

    require = {
      _var = lua "__require";
    };
  };
}
