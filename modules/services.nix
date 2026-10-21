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

  networking.nftables.enable = true;

  services.zapret2 = {
    enable = true;

    firewall = {
      tcpPorts = [ 443 ];
      udpPorts = [ ];
      maxPackets = 16;
    };

    profiles.https = {
      hosts.include = [
        "youtube.com"
        "youtu.be"
        "googlevideo.com"
        "ytimg.com"
        "youtube-nocookie.com"
        "discord.com"
        "discord.gg"
        "discordapp.com"
        "discordapp.net"
        "discord.media"
      ];

      parameters = [
        "--filter-tcp=443"
        "--payload=tls_client_hello"

        "--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1"
        "--lua-desync=fakedsplit:pos=1,midsld:tcp_ts=-1000"
      ];
    };
  };
}
