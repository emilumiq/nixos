{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "2.4.2366";
in
  stdenvNoCC.mkDerivation {
    pname = "suwayomi-server";
    inherit version;

    src = fetchurl {
      url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${version}/Suwayomi-Server-v${version}-macOS-x64.tar.gz";
      hash = "sha256-GHaLLjt/slvz7/nktLFLYjWy3+oyBwGrFy6n+QLuuX4=";
    };

    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/suwayomi $out/bin
      cp -R jre bin $out/share/suwayomi/

      cat > $out/bin/suwayomi-server <<'EOF'
      #!@shell@
      root="''${SUWAYOMI_ROOT:-$HOME/Library/Application Support/Tachidesk}"
      exec "@out@/share/suwayomi/jre/bin/java" \
        --add-exports=java.desktop/sun.awt=ALL-UNNAMED \
        -Dsuwayomi.tachidesk.config.server.rootDir="$root" \
        -jar "@out@/share/suwayomi/bin/Suwayomi-Server.jar" "$@"
      EOF

      substituteInPlace $out/bin/suwayomi-server \
        --subst-var-by shell ${stdenvNoCC.shell} \
        --subst-var-by out $out
      chmod 0755 $out/bin/suwayomi-server

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/Suwayomi/Suwayomi-Server";
      license = lib.licenses.mpl20;
      platforms = ["x86_64-darwin"];
      mainProgram = "suwayomi-server";
    };
  }
