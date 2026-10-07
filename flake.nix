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
        version = "0.3.0";

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
        }:
        let
          target = "${hostname}-${variant}";

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

      common = with pkgs; [
        libpulseaudio
        pkg-config
        gnumake
        age
        gcc

        nixfmt
        nodejs
      ];

      stacks = {
        # quickshell/qml
        quickshell = with pkgs; [
          qt6.qtdeclarative
          qt6.qtpositioning
          gtk4-layer-shell
          qt6.qt5compat
          quickshell
          gtk4
        ];

        rust = with pkgs; [
          rust-analyzer
          rustfmt
          clippy
          cargo
          rustc
        ];

        go = with pkgs; [
          golangci-lint
          gofumpt
          gopls
          go
        ];

        node = with pkgs; [
          vscode-langservers-extracted
          tailwindcss-language-server
          svelte-language-server
          astro-language-server
          typescript
          emmet-ls
          vtsls

          prettier
          eslint_d
          oxlint
          biome
          oxfmt

          pnpm
          bun
        ];

        python = with pkgs; [
          python3Packages.python-lsp-server
          pyright
          ruff
        ];

        lua = with pkgs; [
          luaPackages.luacheck
          lua-language-server
          stylua
        ];

        # languages that here are only ever a language server
        data = with pkgs; [
          postgres-language-server
          vscode-solidity-server
          pgformatter
          checkstyle
          sqlfluff
        ];
      };
    in
    {
      packages.${system} = {
        inherit x;
        nvim = nixvim;
      };

      devShells.${system} =
        (builtins.mapAttrs (_: p: pkgs.mkShell { packages = common ++ p; }) stacks)
        // {
          default = pkgs.mkShell { };
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
        desktop-black = mkHost {
          hostname = "desktop";
          variant = "black";
        };
        desktop-white = mkHost {
          hostname = "desktop";
          variant = "white";
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    quickshell.url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    quickshell.inputs.nixpkgs.follows = "nixpkgs";

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
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

    voxtype.url = "github:peteonrails/voxtype/v1.0.1";
    voxtype.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:Mic92/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };
}
