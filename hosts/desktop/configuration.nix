{
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;

    # mandatory since nvidia 560 and no longer inferred. TU104 is Turing, so the
    # open modules are both supported and what nixpkgs recommends.
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
}
