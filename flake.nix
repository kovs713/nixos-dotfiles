{
  description = "Nixos configuration & dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        "laptop" = inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            ./configuration.nix
            ./hosts/laptop
          ];
        };

        "desktop" = inputs.nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            ./configuration.nix
            ./hosts/desktop
          ];
        };
      };
    };
}
