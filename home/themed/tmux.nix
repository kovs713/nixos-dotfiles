{
  config,
  lib,
  ...
}:
let
  colors = config.lib.stylix.colors;
in
{
  programs.tmux = {
    enable = true;

    # Terminal
    shell = "/run/current-system/sw/bin/fish";
    terminal = "tmux-256color";
    focusEvents = true;

    # Indexing
    baseIndex = 1;

    # Key modes
    keyMode = "vi";

    # Behaviour
    mouse = true;
    aggressiveResize = true;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 2000;

    prefix = "C-Space";

    extraConfig = lib.mkAfter ''
      ### Behaviour
      set -g allow-passthrough on
      set -s extended-keys on
      set -as terminal-features 'xterm-ghostty:extkeys'

      ### Key modes
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle

      ### Prefix
      bind r source-file ~/.config/tmux/tmux.conf

      ### Status bar
      set -g status-position bottom
      set -g status-justify  right
      set -g status-style    bg=default
      set -g status-interval 1

      set -g status-left-length  0
      set -g status-right-length 99

      set -g @tmux_accent      "#${colors.base0D}"
      set -g @tmux_accent_text "#${colors.base00}"
      set -g @tmux_muted       "#${colors.base03}"

      set -g status-left  ""
      set -g status-right " #[bg=#{@tmux_accent},fg=#{@tmux_accent_text}]#(i=$(hyprctl devices 2>/dev/null | sed -n 's/.*active layout index:[[:space:]]*//p' | sort -n | tail -1); hyprctl getoption input:kb_layout 2>/dev/null | sed -n 's/^str:[[:space:]]*//p' | cut -d, -f$((i+1)) | tr '[:lower:]' '[:upper:]')#[default] "

      set -g window-status-format         " #[fg=#{@tmux_muted}]#I:#W "
      set -g window-status-current-format " #[bg=#{@tmux_accent},fg=#{@tmux_accent_text}]#I:#W*#[default] "

      ### Splits
      bind s split-window -h
      bind v split-window -v

      ### Movement
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      ### Rotations
      bind < swap-pane -U
      bind > swap-pane -D

      ### Kill
      bind z kill-pane
      bind x kill-window

      ### Work with windows
      bind c new-window
      bind p previous-window
      bind n next-window
      bind w choose-window

      ### Work with sessions
      bind q choose-session
      bind-key -T choose-tree x kill-session -t "#{session_name}"
      bind -n M-Escape kill-pane

      # Enable OSC 52 clipboard forwarding for remote Neovim yanks.
      set -as terminal-features ",*:clipboard"
    '';
  };
}
