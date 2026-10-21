{ pkgs, nixpkgsSource, ... }:
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

  package = pkgs.neovim-unwrapped.overrideAttrs (old: {
    version = "0.12.6";
    src = old.src.override {
      tag = "v0.12.6";
      hash = "sha256-lK1gbJyESMN3C/i8cyPFzzlJDYZHzEXugGhCwPVEbNk=";
    };
  });

  version.enableNixpkgsReleaseCheck = false;
  colorscheme = "monochrome";
  viAlias = true;
  vimAlias = true;
  withRuby = false;
  withPython3 = true;
  withNodeJs = true;
  extraPackages = [ pkgs.mermaid-cli ];
}
