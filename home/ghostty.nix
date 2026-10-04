{
  ...
}:
{
  programs.ghostty = {
    enable = true;

    settings = {
      # Window
      window-padding-x = 0;
      window-padding-y = 0;
      confirm-close-surface = false;
      resize-overlay = "never";
      background-opacity = 1;

      # Cursor styling
      cursor-style = "block";
      cursor-style-blink = false;
      shell-integration-features = "no-cursor";

      # moving cursor
      custom-shader = "shaders/cursor_sweep.glsl";
    };
  };

  xdg.configFile."ghostty/shaders/cursor_sweep.glsl".text =
    builtins.readFile ./ghostty/shaders/cursor_sweep.glsl;
}
