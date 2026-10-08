# librepods: the AirPods daemon, vendored because nothing packaged will do.
#
# nixpkgs carries librepods 0.2.5, which has no state file, no `status` verb,
# none of the `ca:`/`onebud:`/`adaptive:` verbs and no AirPods Pro 3 model map, so
# a panel cannot read it. This is a modified copy of the same upstream `linux/`
# subtree; src/UPSTREAM.md has the fork point and the diff.
{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  libpulseaudio,
  openssl,
  qt6,
}:

stdenv.mkDerivation {
  pname = "librepods";
  version = "1.0.0-fork";

  src = ./src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    libpulseaudio
    openssl
    qt6.qtbase
    qt6.qtconnectivity
    qt6.qtdeclarative
    qt6.qttools
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = {
    description = "AirPods daemon: battery, listening modes, ear detection";
    homepage = "https://github.com/kavishdevar/librepods";
    license = lib.licenses.gpl3Only;
    mainProgram = "librepods";
    platforms = lib.platforms.linux;
  };
}
