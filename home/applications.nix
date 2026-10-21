{

  programs.obsidian = {
    enable = true;

    vaults.notes.target = "Documents/vault";
  };

  programs.chromium.enable = true;
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    profiles.default = {
      userChrome = builtins.readFile ./themed/zen/userChrome.css;

      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # --- flat / square / borderless ---
        "widget.gtk.rounded-bottom-corners.enabled" = false;
        "zen.theme.border-radius" = 0; # also writes --zen-border-radius
        "zen.theme.content-element-separation" = 0; # also sets [zen-no-padding]
        "zen.view.hide-window-controls" = true;
        "zen.view.compact.enable-at-startup" = true;
        "services.sync.engine.spaces" = true;
      };
    };
  };

  dconf.settings = {
    "org/gnome/nm-applet" = {
      disable-connected-notifications = true;
      disable-disconnected-notifications = true;
      disable-vpn-notifications = true;
      suppress-wireless-networks-available = true;
    };

    "org/blueman/general" = {
      plugin-list = [ "!ConnectionNotifier" ];
    };
  };

}
