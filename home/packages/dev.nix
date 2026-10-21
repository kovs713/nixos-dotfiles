{
  pkgs,
  nixvim,
  x,
  ...
}:
{
  home.packages = with pkgs; [
    lazydocker
    lazygit
    tmux
    yaak
    git
    gh

    tree-sitter
    nest-cli
    nixfmt
    nodejs_latest
    oxlint
    oxfmt
    pnpm
    bun
    nil

    # node
    vscode-langservers-extracted
    tailwindcss-language-server
    svelte-language-server
    astro-language-server
    typescript
    emmet-ls
    vtsls
    prettier
    eslint_d
    biome
    protols
    buf

    # rust
    rust-analyzer
    rustfmt
    clippy
    cargo
    rustc

    # go
    golangci-lint
    gofumpt
    gopls
    go

    # python
    python3
    python3Packages.python-lsp-server
    pyright
    ruff

    # lua
    luaPackages.luacheck
    lua-language-server
    stylua

    # data
    postgres-language-server
    vscode-solidity-server
    pgformatter
    checkstyle

    # native build deps
    age
    gcc
    gnumake
    pkg-config
    libpulseaudio
    gtk4
    gtk4-layer-shell
    qt6.qtdeclarative
    qt6.qtpositioning
    qt6.qt5compat

    (lib.lowPrio minikube) # bundles its own kubectl
    kubectl
    k9s

    zed-editor
    nixvim
    x
  ];

  xdg.configFile."lazygit/config.yml".text = ''
    git:
      overrideGpg: true
  '';
}
