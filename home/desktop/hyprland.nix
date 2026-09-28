{
  lib,
  pkgs,
  ...
}:

let
  lua = lib.generators.mkLuaInline;
  curve = name: spec: {
    _args = [
      name
      (lua spec)
    ];
  };
  anim = spec: {
    _args = [ (lua spec) ];
  };
in
{
  # The other half of the macOS look. The frosted panels are only frosted if
  # there is something behind them to blur, and the dock and menubar only read
  # as macOS if they slide. home/laptop/hyprland turns both off for the
  # laptop's flat bar, so everything it shares is forced back on here.
  #
  # It all goes under `config` on purpose: the shared module puts the flat
  # values in the same subtree, and a value that only *looks* like an override
  # (a top-level `decoration` next to `config.decoration`) is not one — both get
  # rendered, and which wins is the order the settings happen to be sorted in.
  wayland.windowManager.hyprland.settings = {
    config = {
      decoration = {
        rounding = lib.mkForce 10;
        shadow.enabled = lib.mkForce false;
        blur = {
          enabled = lib.mkForce true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          # The shell draws its own translucent panels. A compositor that also
          # blurred them would blur twice and wash the text out.
          ignore_opacity = true;
          noise = 0.02;
          contrast = 0.89;
        };
      };

      animations.enabled = lib.mkForce true;

      misc.disable_hyprland_logo = true;
    };

    # From the rice's config/hypr/custom/general.lua, which is where they were
    # tuned: "Apple restraint, a touch quicker than macOS". Every spring is
    # damped to under 1% overshoot, and the two exits are bezier because
    # macOS dismisses in ~200ms without bounce.
    curve = [
      (curve "spaceGlide" ''{ type = "spring", mass = 1, stiffness = 380, dampening = 32 }'')
      (curve "winPop" ''{ type = "spring", mass = 1, stiffness = 445, dampening = 35 }'')
      (curve "menuSnap" ''{ type = "spring", mass = 1, stiffness = 520, dampening = 40 }'')
      (curve "dragTrack" ''{ type = "spring", mass = 1, stiffness = 600, dampening = 44 }'')
      (curve "outEase" ''{ type = "bezier", points = { { 0.4, 0.0 }, { 0.7, 1.0 } } }'')
      (curve "outSharp" ''{ type = "bezier", points = { { 0.3, 0.0 }, { 0.8, 0.15 } } }'')
    ];

    animation = [
      (anim ''{ leaf = "workspaces", enabled = true, speed = 3, spring = "spaceGlide", style = "slide" }'')
      (anim ''{ leaf = "specialWorkspaceIn", enabled = true, speed = 3, spring = "winPop", style = "slidevert" }'')
      (anim ''{ leaf = "specialWorkspaceOut", enabled = true, speed = 1.6, bezier = "outEase", style = "slidevert" }'')
      (anim ''{ leaf = "windowsIn", enabled = true, speed = 3, spring = "winPop", style = "popin 90%" }'')
      (anim ''{ leaf = "windowsOut", enabled = true, speed = 1.6, bezier = "outEase", style = "popin 92%" }'')
      (anim ''{ leaf = "windowsMove", enabled = true, speed = 3, spring = "dragTrack", style = "slide" }'')
      (anim ''{ leaf = "border", enabled = true, speed = 3, spring = "menuSnap" }'')
      (anim ''{ leaf = "fadeIn", enabled = true, speed = 3, spring = "menuSnap" }'')
      (anim ''{ leaf = "fadeOut", enabled = true, speed = 1.4, bezier = "outSharp" }'')
      # The layers are the menubar, the dock and the launcher: crisp, no bounce.
      (anim ''{ leaf = "layersIn", enabled = true, speed = 3, spring = "menuSnap", style = "popin 92%" }'')
      (anim ''{ leaf = "layersOut", enabled = true, speed = 1.2, bezier = "outEase", style = "popin 95%" }'')
      (anim ''{ leaf = "fadeLayersIn", enabled = true, speed = 3, spring = "menuSnap" }'')
      (anim ''{ leaf = "fadeLayersOut", enabled = true, speed = 1.4, bezier = "outSharp" }'')
    ];
  };
}
