{
  stylix.targets.gtk.extraCss = ''
    messagedialog button:hover {
      background-color: @accent_color;
    }

    banner revealer widget {
      background: @shade_color;
      padding: 5px;
      color: @window_fg_color;
    }

    alertdialog.background {
      background-color: @dialog_bg_color;
      color: @dialog_fg_color;
    }

    alertdialog .titlebar {
      background-color: @headerbar_bg_color;
      color: @headerbar_fg_color;
    }

    alertdialog box {
      background-color: @dialog_bg_color;
    }

    alertdialog label {
      color: @dialog_fg_color;
    }

    filechooser .dialog-action-box {
      border-top: 1px solid @shade_color;
    }

    filechooser .dialog-action-box:backdrop {
      border-top-color: @view_bg_color;
    }

    filechooser #pathbarbox {
      border-bottom: 1px solid @shade_color;
    }

    filechooserbutton:drop(active) {
      box-shadow: none;
      border-color: transparent;
    }

    toast {
      background-color: @view_bg_color;
      color: @window_fg_color;
    }

    toast button.circular.flat.image-button:hover {
      color: @window_bg_color;
      background-color: @error_color;
    }
  '';
}
