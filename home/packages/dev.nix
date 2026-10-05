{
  pkgs,
  nixvim,
  x,
  ...
}:
{
  home.packages = with pkgs; [
    lazygit
    tmux
    git
    gh

    tree-sitter
    nixfmt
    nodejs
    nil

    (lib.lowPrio minikube) # bundles its own kubectl
    kubectl
    k9s

    nixvim
    x
  ];

  xdg.configFile."lazygit/config.yml".text = ''
    git:
      overrideGpg: true
  '';
}
