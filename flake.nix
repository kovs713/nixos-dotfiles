{
  description = "Nixos configuration & dotfiles";

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      nixvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
        module = import ./packages/nixvim/config {
          inherit pkgs;
          nixpkgsSource = inputs.nixpkgs.outPath;
        };
      };

      x = pkgs.buildGoModule {
        pname = "x";
        version = "0.2.0";

        src = ./packages/x;
        vendorHash = null;

        ldflags = [
          "-s"
          "-w"
        ];
      };

      mkHost =
        {
          hostname,
          variant,
          target ? "${hostname}-${variant}",
        }:
        let
          specialArgs = {
            inherit
              system
              hostname
              variant

              nixvim
              x

              inputs
              ;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;

          modules = [
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [
                inputs.apple-fonts.overlays.default

                (final: prev: {
                  zen-browser = inputs.zen-browser.packages.${system}.default;
                })
              ];

            }

            ({ config, pkgs, ... }: {
              environment.systemPackages = [ x ];

              environment.etc."x/target".text = target;
            })

            home-manager.nixosModules.home-manager
            ./home

            inputs.nixvim.nixosModules.nixvim
            ./packages/nixvim

            ./modules
            ./hosts/${hostname}
          ];
        };
    in
    {
      packages.${system} = {
        inherit x;
        nvim = nixvim;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # gtk
          gtk4
          gtk4-layer-shell

          # cli
          cargo
          rustc
          rustfmt
          clippy
          pkg-config
          libpulseaudio
          jq
          gcc
          pnpm
          bun
          go
          gnumake
          kubectl

          # lsp
          qt6.qtdeclarative
          rust-analyzer
          python3Packages.python-lsp-server
          typescript-language-server
          vtsls
          vue-language-server
          astro-language-server
          svelte-language-server
          emmet-ls
          gopls
          tailwindcss-language-server
          vscode-langservers-extracted
          biome
          ruff
          pyright
          postgres-language-server
          vscode-solidity-server
          lua-language-server

          # formatters
          prettier
          oxlint
          stylua
          gofumpt
          shfmt
          pgformatter

          # linters
          eslint_d
          golangci-lint
          luaPackages.luacheck
          checkstyle
          sqlfluff
        ];
      };

      nixosConfigurations = {
        laptop-black = mkHost {
          hostname = "laptop";
          variant = "black";
        };
        laptop-white = mkHost {
          hostname = "laptop";
          variant = "white";
        };
        desktop = mkHost {
          hostname = "desktop";
          variant = "black";
          target = "desktop";
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.home-manager.follows = "home-manager";

    stylix.url = "github:nix-community/stylix/master";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    apple-fonts.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:kovs713/Hyprland?ref=feat/omit-capture";

    voxtype.url = "github:peteonrails/voxtype/v1.0.1";
  };
}
