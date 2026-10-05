{ pkgs, ... }:
{
  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", MODE="0660", GROUP="users"
  '';

  environment.systemPackages = with pkgs; [
    cryptsetup
    e2fsprogs

    udisks
    gnome-disk-utility
    gvfs
  ];

  services.udisks2.enable = true;

  # 2TB NTFS data disk
  boot.kernelModules = [
    "ntfs3"
    "i2c-dev" # /dev/i2c-*, for the ddcutil monitor brightness
  ];

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
