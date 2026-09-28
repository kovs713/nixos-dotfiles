{ pkgs, ... }:
{
  boot.loader.limine.enable = true;
  boot.loader.limine.efiInstallAsRemovable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16384;
    }
  ];

  zramSwap.enable = true;
}
