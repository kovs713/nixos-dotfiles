{
  inputs,
  lib,
  system,
  ...
}:
let
  voxtype = inputs.voxtype.packages.${system};
in
{
  home.packages = [
    voxtype.default
    voxtype."osd-gtk4"
  ];

  home.activation.voxtypeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/.config/voxtype/config.toml"

    if [ ! -e "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      install -Dm644 ${voxtype.default}/share/voxtype/default-config.toml "$dest"
    fi
  '';

  systemd.user.services.voxtype = {
    Service.ExecStart = "${lib.getExe voxtype.default} daemon";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
