{
  pkgs,
  inputs,
  ...
}:
{
  # `nixpkgsSource` is the same expression in both callers because there are two
  # of them and it is one line: flake.nix builds the nixvim package with this
  # module, and the NixOS module here wraps the result. The setting itself lives
  # in config/default.nix, so it applies on both paths.
  programs.nixvim =
    (import ./config {
      inherit pkgs;
      nixpkgsSource = inputs.nixpkgs-unstable.outPath;
    })
    // {
      enable = true;
    };
}
