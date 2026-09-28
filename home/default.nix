{
  pkgs-unstable,
  x,
  nixvim,
  inputs,
  system,
  hostname,
  variant,
  lib,
  ...
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.overwriteBackup = true;
  home-manager.extraSpecialArgs = {
    inherit
      pkgs-unstable
      inputs
      x
      nixvim
      system
      hostname
      variant
      ;
  };

  home-manager.users.kovs.imports = [
    inputs.hyprland.homeManagerModules.default
    inputs.zen-browser.homeModules.default
    ./home.nix
  ]
  ++ lib.optional (hostname == "desktop") ./desktop;
}
