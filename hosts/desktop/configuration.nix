{
  lib,
  ...
}:
{
  # The laptop gets this from its generated hardware-configuration.nix. The
  # desktop has none, and nixpkgs 26.05 no longer falls back to the builder's
  # system, so `nixosConfigurations.desktop` did not evaluate at all without it.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
