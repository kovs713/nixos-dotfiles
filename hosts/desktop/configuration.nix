{ pkgs, ... }:
{
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  environment.systemPackages = with pkgs; [
    cryptsetup
    e2fsprogs

    udisks
    gnome-disk-utility
    gvfs
  ];

  services.udisks2.enable = true;

  # 2TB NTFS data disk
  boot.kernelModules = [ "ntfs3" ];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/0C6711E40C6711E4";
    fsType = "ntfs3";
    options = [
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=10"
    ];
  };

  # 480GB LUKS disk (sdc2), btrfs with the old omarchy install
  environment.etc."crypttab".text = ''
    cryptdata UUID=192da2fb-4250-4e06-a490-5a0f55d4b34d none luks
  '';

  fileSystems."/mnt/cryptdata" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "nofail"
      "compress=zstd"
      "x-systemd.requires=systemd-cryptsetup@cryptdata.service"
      "x-systemd.after=systemd-cryptsetup@cryptdata.service"
    ];
  };
}
