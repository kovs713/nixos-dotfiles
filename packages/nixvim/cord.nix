{ pkgs }:
let
  inherit (pkgs)
    lib
    vimUtils
    stdenvNoCC
    fetchFromGitHub
    fetchurl
    ;

  version = "2.3.29";

  src = fetchFromGitHub {
    owner = "vyfor";
    repo = "cord.nvim";
    tag = "v${version}";
    hash = "sha256-zQNkfw3YrEvs9JMgC5UnVE09S/bCIRT+R1j4KaAA0Kc=";
  };

  cordServer = stdenvNoCC.mkDerivation {
    pname = "cord";
    inherit version;

    src = fetchurl {
      url = "https://github.com/vyfor/cord.nvim/releases/download/v${version}/x86_64-linux-cord";
      hash = "sha256-uz1St9qynx9J3F76gexYsA5yitr8Q/pv+I+vlO+iSzs=";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm444 $src $out/bin/cord
      chmod +x $out/bin/cord
      runHook postInstall
    '';

    meta.mainProgram = "cord";
  };
in
vimUtils.buildVimPlugin {
  pname = "cord.nvim";
  inherit version src;

  postPatch = ''
    substituteInPlace .github/server-version.txt \
      --replace-fail "2.3.13" "${version}"

    # https://github.com/vyfor/cord.nvim/blob/v${version}/lua/cord/server/fs/init.lua
    substituteInPlace lua/cord/server/fs/init.lua \
      --replace-fail "or M.get_data_path()" "or '${cordServer}'"
  '';

  nvimSkipModules = [ "cord.api.log.file" ];

  meta = {
    homepage = "https://github.com/vyfor/cord.nvim";
    license = lib.licenses.asl20;
    changelog = "https://github.com/vyfor/cord.nvim/releases/tag/v${version}";
  };
}
