{ pkgs, ... }:
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./autocmds.nix
    ./plugins.nix
    ./plugins-lua.nix
    ./lsp.nix
    ./runtime.nix
  ];

  programs.nixvim = {
    enable = true;
    colorscheme = "monochrome";
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = true;
    withNodeJs = true;
  };
}
