{
  services.getty.autologinUser = "kovs";

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
    jack.enable = true;
    audio.enable = true;
  };

  services.smartd = {
    enable = true;
    autodetect = true;
  };
}
