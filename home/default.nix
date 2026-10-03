{
  specialArgs,
  hostname,

  inputs,
  ...
}:
let
  hostnameDir = if hostname == "desktop" then ./desktop else ./laptop;
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.overwriteBackup = true;
  home-manager.extraSpecialArgs = specialArgs;

  home-manager.users.kovs.imports = [
    inputs.hyprland.homeManagerModules.default
    inputs.zen-browser.homeModules.default
    ./home.nix
    hostnameDir
  ];
}
