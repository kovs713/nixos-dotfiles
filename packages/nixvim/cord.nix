# cord.nvim, ahead of the nixpkgs pin.
#
# nixpkgs has 2.2.7, whose icon set is three themes (`default`, `atom`,
# `catppuccin`) and whose schema has no `display.view`. Current upstream is
# 2.3.29: six themes including `minecraft`, `void` and `classic`, and the view
# modes. So a config written against the documented defaults warns on start:
#
#   [cord.nvim] Unknown theme: minecraft
#   Unknown configuration entry: `display.view`
#   Unknown configuration entry: `timestamp.shared`
#
# The theme warning is the only visible one because a theme is just a string, so
# it passes schema validation and is only caught when the status is drawn. The
# other two are warnings the config validator prints and nobody was looking for.
#
# This is the nixpkgs expression with the version moved forward, so an upstream
# bump makes this file deletable. The PR for that is the one thing here that is
# not a local workaround; until it lands, this is what keeps the config as
# written. See the comment at the bottom for what the PR needs.
#
# The server is the release asset rather than a cargo build of the bundled Rust
# source, which is what nixpkgs does. The asset is a static-pie binary: no
# interpreter, no NEEDED entries, so it runs on any Linux and needs nothing but
# +x. That is the whole reason this is shorter than the nixpkgs expression and
# carries no cargoHash.
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

  # `M.get_executable_path` returns `<base>/bin/cord`, and the postPatch below
  # replaces the base with this output, so the layout here is load-bearing.
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
    # The version in .github/server-version.txt is the one the plugin checks the
    # running server against, and it does not track Cargo.toml. Unpatched, the
    # server reports 2.3.13 against a 2.3.29 plugin and refuses to run.
    substituteInPlace .github/server-version.txt \
      --replace-fail "2.3.13" "${version}"

    # Point the plugin at the Nix-built server instead of the one it downloads
    # into stdpath('data') on first run. Still overridable per user through
    # config.advanced.server.executable_path.
    # https://github.com/vyfor/cord.nvim/blob/v${version}/lua/cord/server/fs/init.lua
    substituteInPlace lua/cord/server/fs/init.lua \
      --replace-fail "or M.get_data_path()" "or '${cordServer}'"
  '';

  # lua/cord/api/log/file.lua notifies at ERROR level on load when CORD_LOG_FILE
  # is unset, and the require check counts a non-zero exit as a failure. The
  # require itself succeeds; the module is only useful with that variable set,
  # and it is a logger, so nothing at load time depends on it.
  nvimSkipModules = [ "cord.api.log.file" ];

  meta = {
    homepage = "https://github.com/vyfor/cord.nvim";
    license = lib.licenses.asl20;
    changelog = "https://github.com/vyfor/cord.nvim/releases/tag/v${version}";
  };

  # Not for upstream. The nixpkgs bump is a version and a cargoHash, and it
  # belongs in NixOS/nixpkgs as `vimPlugins.cord-nvim: 2.2.7 -> 2.3.29` — the
  # expression there already has `passthru.updateScript = nix-update-script`, so
  # `nix-update --to-version 2.3.29 vimPlugins.cord-nvim` writes the PR and
  # discovers the hash by building. Its last bump was #412404.
  #
  # That PR keeps rustPlatform.buildRustPackage. It should: the release asset
  # used here is a local trade, not a proposal, and the maintainer is active.
  # So this file is expected to disappear once that lands, and until then the
  # only thing it has to get right is the two postPatch substitutions and the
  # version.
}
