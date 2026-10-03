{ pkgs, inputs, ... }:
{
  programs.nixvim =
    (import ./config {
      inherit pkgs;
      nixpkgsSource = inputs.nixpkgs.outPath;
    })
    // {
      enable = true;
    };
}
