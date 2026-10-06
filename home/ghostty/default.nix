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

      # ghostty is just a window, tmux owns everything inside it, so nuke all default binds
      keybind = [
        "clear"

        # clipboard
        "copy=copy_to_clipboard:mixed"
        "paste=paste_from_clipboard"
        "ctrl+insert=copy_to_clipboard:mixed"
        "shift+insert=paste_from_selection"
        "ctrl+shift+c=copy_to_clipboard:mixed"
        "ctrl+shift+v=paste_from_clipboard"

        # selection + scrollback
        "shift+arrow_up=adjust_selection:up"
        "shift+arrow_down=adjust_selection:down"
        "shift+arrow_left=adjust_selection:left"
        "shift+arrow_right=adjust_selection:right"
        "shift+home=scroll_to_top"
        "shift+end=scroll_to_bottom"
        "shift+page_up=scroll_page_up"
        "shift+page_down=scroll_page_down"

        # window
        "ctrl+equal=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+0=reset_font_size"
        "ctrl+enter=toggle_fullscreen"
        "alt+f4=close_window"

        # config
        "ctrl+,=open_config"
        "ctrl+shift+,=reload_config"
      ];
    };
  };

  xdg.configFile."ghostty/shaders/cursor_sweep.glsl".text =
    builtins.readFile ./shaders/cursor_sweep.glsl;
}
