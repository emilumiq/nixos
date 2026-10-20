{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  uv,
  git,
  python314,
  cacert,
  coreutils,
  frontend ? null,
}: let
  version = "2.2.0";
  envPath = lib.makeBinPath [uv git coreutils cacert];
in
  stdenvNoCC.mkDerivation {
    pname = "anibridge";
    inherit version;

    src = fetchFromGitHub {
      owner = "anibridge";
      repo = "anibridge";
      rev = "v${version}";
      hash = "sha256-h6iFopLrwP+Whh331v9Ur/bKbWo3FhgtDR/XlQxgf34=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/anibridge $out/bin
      cp -R . $out/share/anibridge/

      ${
        if frontend != null
        then ''
          mkdir -p $out/share/anibridge/frontend/build
          cp -R ${frontend}/. $out/share/anibridge/frontend/build/
        ''
        else ""
      }

      cat > $out/bin/anibridge <<'EOF'
      #!@shell@
      export PATH="@envPath@:$PATH"
      export SSL_CERT_FILE="@cacert@/etc/ssl/certs/ca-bundle.crt"
      export GIT_SSL_CAINFO="$SSL_CERT_FILE"
      export PYTHONPATH="@out@/share/anibridge/src''${PYTHONPATH:+:$PYTHONPATH}"
      export UV_PROJECT_ENVIRONMENT="''${ANIBRIDGE_VENV:-$HOME/Library/Application Support/anibridge/venv}"
      if [ ! -x "$UV_PROJECT_ENVIRONMENT/bin/python" ]; then
        @uv@/bin/uv sync --frozen --no-dev --project "@out@/share/anibridge" --python @python@/bin/python
      fi
      exec "$UV_PROJECT_ENVIRONMENT/bin/python" "@out@/share/anibridge/main.py" "$@"
      EOF

      substituteInPlace $out/bin/anibridge \
        --subst-var-by shell ${stdenvNoCC.shell} \
        --subst-var-by envPath ${envPath} \
        --subst-var-by cacert ${cacert} \
        --subst-var-by uv ${uv} \
        --subst-var-by python ${python314} \
        --subst-var-by out $out
      chmod 0755 $out/bin/anibridge

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/anibridge/anibridge";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
      mainProgram = "anibridge";
    };
  }
