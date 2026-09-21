{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.limine.enable = true;
  boot.loader.limine.efiInstallAsRemovable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16384;
    }
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  services.syncthing = {
    enable = true;
    dataDir = "/home/kovs/Documents/tony-stark";
    configDir = "/home/kovs/.config/syncthing";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-mono
  ];

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "b9a18a606f20c9aa"
    ];
  };

  services.getty.autologinUser = "kovs";

  services.kmscon = {
    enable = true;
    fonts = [
      {
        name = "CaskaydiaMono Nerd Font";
        package = pkgs.nerd-fonts.caskaydia-mono;
      }
    ];
    extraConfig = ''
      font-engine=pango
      font-size=20
    '';
    useXkbConfig = true;
  };
  services.xserver.xkb.options = "caps:escape";

  time.timeZone = "Europe/Tbilisi";
  i18n.defaultLocale = "en_US.UTF-8";

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  programs.fish.enable = true;
  users.users.kovs = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialPassword = " ";
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    wget
    curl
    fish

    fastfetch
    lazygit
    ripgrep
    fd
    zoxide
    tmux
    tree
    tree-sitter
    lua-language-server
    nil
    nixfmt
    rust-analyzer
    python3Packages.python-lsp-server
    stylua
    nodejs
    pnpm
    bun
    go
    gopls
    gofumpt
    gcc
    gnumake
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      glibc
      zlib
      openssl
      icu
      libffi
    ];
  };

  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;

  networking.firewall.enable = true;
  networking.firewall.interfaces.zt0.allowedTCPPorts = [
    22000
    22000
    8384
  ];
  networking.firewall.interfaces.zt0.allowedUDPPorts = [
    22000
    21027
  ];

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  system.stateVersion = "26.05";
}
