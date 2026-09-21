{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.syncthing = {
    user = "nixos-laptop";
  };

  # services.power-profiles-daemon.enable = true;
  services.tlp.enable = true;
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
  };

  services.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    acpi
  ];
}
