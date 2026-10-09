{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "photocraft";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-9U2GOAcFO738/6DWJO9+SdP9QTEMe7Ht5IU29pkp0i8=";
  };

  extracted = appimageTools.extract { inherit pname version src; };
in

appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp ${extracted}/ai.storyteller.photocraft.desktop $out/share/applications/
    cp ${extracted}/ai.storyteller.photocraft.png $out/share/icons/hicolor/256x256/apps/
  '';

  meta = {
    description = "Open-source Photoshop reimplementation in Rust";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "photocraft";
    platforms = [ "x86_64-linux" ];
  };
}
