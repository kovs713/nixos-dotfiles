{
  config,
  hostname,
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

  # same accessor quickshell/theme.json uses; hyprlock wants colours as
  # strings, and #rrggbb is what Hyprlang colours are everywhere else too
  c = n: config.lib.stylix.colors.withHashtag.${n};

  quickshellBinds =
    lib.optionals (hostname == "desktop") [
      (bind "${mod} + SPACE" (exec "vicinae toggle"))
    ]
    ++ lib.optionals (hostname != "desktop") [
      (bind "${mod} + B" (exec "qs ipc call bar toggleAutoReveal"))
      (bind "${mod} + V" (exec "qs ipc call clipboard toggle"))
      (bind "${mod} + N" (exec "qs ipc call notes toggle"))
      (bind "${mod} + SHIFT + N" (exec "qs ipc call nightlight toggle"))
      (bind "${mod} + CTRL + E" (exec "qs ipc call emoji toggle"))
      (bind "${mod} + SPACE" (exec "qs ipc call launcher toggle"))
    ];
in
{
  home.packages = with pkgs; [
    awww
    hyprcursor
    hypridle
    hyprlock
    hyprshot
    hyprpicker
  ];

  xdg.configFile."hypr/hyprlock.conf".text = ''
    animations {
        enabled = false
    }

    general {
        hide_cursor = true
    }

    background {
        monitor =
        color = ${c "base00"}
    }

    input-field {
        monitor =
        size = 320, 56

        rounding = 0
        dots_rounding = 0
        dots_size = 0.22
        dots_spacing = 0.18

        outline_thickness = 1
        outer_color = ${c "base02"}
        inner_color = ${c "base00"}
        font_color = ${c "base05"}

        font_family = ${config.stylix.fonts.sansSerif.name}
        fade_on_empty = false
        placeholder_text = <i>$USER</i>

        check_color = ${c "base0B"}
        fail_color = ${c "base08"}

        halign = center
        valign = center
    }
  '';

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
        # without this the display stays off and you need a second keypress
        after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
    }

    listener {
        timeout = 150
        on-timeout = brightnessctl -s set 10
        on-resume = brightnessctl -r
    }

    listener {
        timeout = 300
        on-timeout = loginctl lock-session
    }

    listener {
        timeout = 330
        on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'
        on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' && brightnessctl -r
    }

    listener {
        timeout = 1800
        on-timeout = systemctl suspend
    }
  '';

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

    hypridle = {
      Unit.Description = "Hyprland idle management";
      Service = {
        ExecStart = lib.getExe pkgs.hypridle;
        Restart = "on-failure";
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
        mode = "preferred";
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

    window_rule = [
      {
        name = "bitwarden";
        match = {
          title = ".*Bitwarden Password Manager.*";
        };
        float = true;
      }
    ];

    bind = [
      (bind "${mod} + Q" (exec "xdg-terminal-exec"))
      (bind "${mod} + C" "hl.dsp.window.close()")
      (bind "${mod} + F" ''hl.dsp.window.float({ action = "toggle" })'')
      (bind "${mod} + X" (exec "voxtype record toggle"))

      # Screenshot
      (bind "CTRL + Print" (exec "hyprpicker -a"))
      (bind "Print" (exec "hyprshot -m region -z --clipboard-only"))

      (bind "${mod} + mouse:272" "hl.dsp.window.drag()")
      (bind "${mod} + mouse:273" "hl.dsp.window.resize()")

      (bind "F7" (exec "test -r /tmp/olay-overlay.pid && kill -USR1 \"$(cat /tmp/olay-overlay.pid)\""))
      (bind "F8" (exec "test -r /tmp/olay-overlay.pid && kill -USR2 \"$(cat /tmp/olay-overlay.pid)\""))

      (bind "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      (bindRepeat "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
      (bindRepeat "XF86AudioLowerVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"))
      (bindRepeat "XF86MonBrightnessUp" (exec "brightnessctl -e4 -n2 set 5%+"))
      (bindRepeat "XF86MonBrightnessDown" (exec "brightnessctl -e4 -n2 set 5%-"))

      (bind "${mod} + SHIFT + T" (exec "x theme"))

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
    ]
    ++ quickshellBinds;

    config = {
      general = {
        gaps_in = 0;
        gaps_out = 0;

        border_size = 2;

        layout = "scrolling";
      };

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_space_toggle,caps:escape";
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
