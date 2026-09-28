{
  pkgs,
  pkgs-unstable,
  nixvim,
  x,
  ...
}:
{
  home.packages =
    (with pkgs; [
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
    ])
    ++ (with pkgs-unstable; [
      opencode
    ]);
}
