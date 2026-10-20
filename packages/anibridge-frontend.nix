{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs_22,
  pnpm,
  pnpmConfigHook,
}: let
  version = "2.2.0";
  src = fetchFromGitHub {
    owner = "anibridge";
    repo = "anibridge";
    rev = "v${version}";
    hash = "sha256-h6iFopLrwP+Whh331v9Ur/bKbWo3FhgtDR/XlQxgf34=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "anibridge-frontend";
    inherit version src;

    sourceRoot = "source/frontend";

    pnpmDeps = fetchPnpmDeps {
      pname = "anibridge-frontend";
      inherit version;
      src = "${src}/frontend";
      fetcherVersion = 3;
      hash = "sha256-D0J2GiCkcnPMUe4wwN0+ATWCpEwjyR7vE08FJ/W57MI=";
    };

    nativeBuildInputs = [nodejs_22 pnpm pnpmConfigHook];

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -R build $out
      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/anibridge/anibridge";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
