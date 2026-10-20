{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}: let
  version = "2.36.1";
in
  stdenvNoCC.mkDerivation {
    pname = "vuetorrent";
    inherit version;

    src = fetchurl {
      url = "https://github.com/VueTorrent/VueTorrent/releases/download/v${version}/vuetorrent.zip";
      hash = "sha256-cLZ1MfDzvDbIvQXYLMe6HuN8ccF/C2xF9SIgDjXmbzc=";
    };

    nativeBuildInputs = [unzip];
    dontBuild = true;

    unpackPhase = ''
      unzip -q "$src" -d .
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R vuetorrent/public $out/public
      cp vuetorrent/version.txt $out/version.txt
      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/VueTorrent/VueTorrent";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
