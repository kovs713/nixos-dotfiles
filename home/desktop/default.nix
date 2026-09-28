{
  lib,
  pkgs,
  ...
}:

let
  macShell = pkgs.runCommand "macshell-config" { } ''
    mkdir -p "$out"
    cp -r ${./quickshell}/. "$out/"
    chmod -R u+w "$out"
    chmod -R u-w "$out"
  '';
in
{
  imports = [ ./hyprland.nix ];

  xdg.configFile."quickshell" = lib.mkForce { source = macShell; };

  home.packages = with pkgs; [
    # The shell's own launcher (SUPER+SPACE). end-4's was the notch, and vicinae
    # replaces it rather than the launcher being reimplemented.
    vicinae

    # The visualiser in MediaControls.
    cava

    # Config.options.apps — every one of these is a menu row that would
    # otherwise run a KDE command and fail silently. nm-connection-editor is not
    # in nixpkgs, so connections are edited with the GTK one.
    pavucontrol
    gnome-connections
    gnome-system-monitor
    nautilus
    tesseract

    # CaptureMenu's fullscreen and OCR rows.
    grim
    slurp

    # Appearance.font.family.iconMaterial is "Material Symbols Rounded" and
    # every icon in the shell is a glyph from it, not an SVG. Without this
    # package the whole UI is boxes — and nothing fails loudly, because a font
    # family that does not resolve is not an error in Qt.
    material-symbols
  ];

  # Seeded once, then never again: the shell rewrites config.json whole the
  # first time it changes anything, so a symlink would fail the write, and a
  # plain "seed if absent" would lose to the shell writing its own defaults at
  # first boot — before this activation ever runs. The marker is what makes
  # "our seed, then the user's" true regardless of which happens first.
  home.activation.macShellConfig = ''
    marker="$HOME/.local/state/quickshell/macshell-config.json"
    if [ ! -e "$marker" ]; then
      mkdir -p "$HOME/.config/illogical-impulse"
      install -m 644 ${./config.json} "$HOME/.config/illogical-impulse/config.json"
      mkdir -p "$(dirname "$marker")"
      : >"$marker"
    fi
  '';
}
