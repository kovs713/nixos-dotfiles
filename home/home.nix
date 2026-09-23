{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  lua = lib.generators.mkLuaInline;
  mod = "SUPER";

  env = key: value: {
    _args = [
      key
      value
    ];
  };

  bind = keys: disp: {
    _args = [
      keys
      (lua disp)
    ];
  };
  exec = cmd: "hl.dsp.exec_cmd([[${cmd}]])";

  moveWorkspace = workspace: ''hl.dsp.window.move({ workspace = "${workspace}"})'';

  focusWorkspace = workspace: ''hl.dsp.focus({workspace = "${workspace}"})'';
  focusDirection = direction: ''hl.dsp.focus({direction = "${direction}"})'';
in
{
  home.username = "kovs";
  home.homeDirectory = "/home/kovs";

  programs.home-manager.enable = true;
  programs.ghostty.enable = true;

  xdg.terminal-exec = {
    enable = true;
    settings.default = [
      "ghostty.desktop"
    ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;

    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    settings = {
      monitor = [
        {
          output = "";
          mode = "prefered";
          position = "auto";
          scale = "1";
        }
      ];

      env = [
        (env "XCURSOR_SIZE" "24")
        (env "HYPRCURSOR_SIZE" "24")
      ];

      bind = [
        (bind "${mod} + Q" (exec "xdg-terminal-exec"))
        (bind "${mod} + C" "hl.dsp.window.close()")

        (bind "${mod} + 1" (focusWorkspace "1"))
        (bind "${mod} + 2" (focusWorkspace "2"))
        (bind "${mod} + 3" (focusWorkspace "3"))
        (bind "${mod} + 4" (focusWorkspace "4"))

        (bind "${mod} + h" (focusDirection "l"))
        (bind "${mod} + j" (focusDirection "d"))
        (bind "${mod} + k" (focusDirection "u"))
        (bind "${mod} + l" (focusDirection "r"))

        (bind "${mod} + 1" (moveWorkspace "1"))
        (bind "${mod} + 2" (moveWorkspace "2"))
        (bind "${mod} + 3" (moveWorkspace "3"))
        (bind "${mod} + 4" (moveWorkspace "4"))

        (bind "${mod} + mouse:272" "hl.dsp.window.drag()")
        (bind "${mod} + mouse:273" "hl.dsp.window.resize()")
      ];

      config = {
        input = {
          kb_layout = "us,ru";
          kb_options = "grp:alt_shift_toggle,caps:escape";
        };
      };
    };
  };

  home.packages = with pkgs; [
    # lsp servers
    vtsls
    vue-language-server
    astro-language-server
    svelte-language-server
    emmet-ls
    gopls
    tailwindcss-language-server
    vscode-langservers-extracted # html, cssls, jsonls
    biome
    lua-language-server
    ruff
    pyright
    postgres-language-server
    vscode-solidity-server

    # formatters (conform)
    prettier
    oxlint
    stylua
    gofumpt
    shfmt
    pgformatter # provides pg_format

    # linters (nvim-lint)
    eslint_d
    golangci-lint
    luaPackages.luacheck
    checkstyle
    sqlfluff # ftplugin sql formatprg
  ];

  home.stateVersion = "26.05";
}
