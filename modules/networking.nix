{ ... }:
{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "b9a18a606f20c9aa"
    ];
  };

  security.rtkit.enable = true;
  security.polkit.enable = true;
  services.openssh.enable = true;

  networking.nameservers = [
    "8.8.8.8"
    "1.1.1.1"
  ];
  networking.firewall.enable = true;
  networking.firewall.interfaces.zt0.allowedTCPPorts = [
    22000
    8384
  ];
  networking.firewall.interfaces.zt0.allowedUDPPorts = [
    22000
    21027
  ];
}
