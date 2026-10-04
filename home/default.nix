{
  specialArgs,
  hostname,

  inputs,
  lib,
  ...
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.overwriteBackup = true;
  home-manager.extraSpecialArgs = specialArgs;

  home-manager.users.kovs.imports = [
    inputs.hyprland.homeManagerModules.default
    inputs.zen-browser.homeModules.default
    inputs.agenix.homeManagerModules.age

    ./home.nix
  ]
  ++ lib.optional (hostname == "laptop") ./laptop;
}
