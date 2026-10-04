{
  config,
  pkgs,
  lib,
  ...
}:
let
  colors = n: config.lib.stylix.colors.withHashtag.${n};
in
{
  home.packages = with pkgs; [
    hypridle
    hyprlock
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
        color = ${colors "base00"}
    }

    input-field {
        monitor =
        size = 320, 56

        rounding = 0
        dots_rounding = 0
        dots_size = 0.22
        dots_spacing = 0.18

        outline_thickness = 1
        outer_color = ${colors "base02"}
        inner_color = ${colors "base00"}
        font_color = ${colors "base05"}

        font_family = ${config.stylix.fonts.sansSerif.name}
        fade_on_empty = false
        placeholder_text = <i>$USER</i>

        check_color = ${colors "base0B"}
        fail_color = ${colors "base08"}

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

  systemd.user.services.hypridle = {
    Unit.Description = "Hyprland idle management";
    Service = {
      ExecStart = lib.getExe pkgs.hypridle;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
