{ pkgs, inputs, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };

  home-manager.users.kovs.imports = [
    inputs.hyprland.homeManagerModules.default
    ./home.nix
  ];
}
