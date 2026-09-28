{
  nixpkgsSource,
  ...
}:
{
  imports = [
    ./options.nix
    ./ftplugin.nix
    ./keymaps.nix
    ./autocmds.nix
    ./plugins.nix
    ./lsp.nix
    ./lua.nix
  ];

  nixpkgs.source = nixpkgsSource;

  version.enableNixpkgsReleaseCheck = false;
  colorscheme = "monochrome";
  viAlias = true;
  vimAlias = true;
  withRuby = false;
  withPython3 = true;
  withNodeJs = true;
}
