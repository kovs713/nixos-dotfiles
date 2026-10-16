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
    nodejs
    oxlint
    oxfmt
    pnpm
    bun
    nil

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
