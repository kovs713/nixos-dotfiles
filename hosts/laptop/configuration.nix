{ pkgs, ... }:
{
  services.syncthing = {
    user = "nixos-laptop";
  };

  services.tlp.pd.enable = true;
  services.tlp.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
  };

  services.libinput.enable = true;

  security.pam.services.hyprlock = { };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  environment.systemPackages = with pkgs; [
    acpi
    iw
    powertop
  ];
}
