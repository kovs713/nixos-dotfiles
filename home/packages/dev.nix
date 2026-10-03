{
  pkgs,
  nixvim,
  x,
  ...
}:
{
  home.packages = with pkgs; [
    opencode
    lazygit
    tmux
    git
    gh

    tree-sitter
    nixfmt
    nodejs
    nil

    nixvim
    x
  ];
}
