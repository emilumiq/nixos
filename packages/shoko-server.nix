{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  mediainfo,
}: let
  version = "6.0.0-alpha.109";
in
  buildDotnetModule {
    pname = "shoko-server";
    inherit version;

    src = fetchFromGitHub {
      owner = "ShokoAnime";
      repo = "ShokoServer";
      rev = "3c153793d0c1a3d4e1582f7db75cf91282564027";
      hash = "sha256-YmDzdeiwtWYs1YGbmkx/ysCqge+mTq2p+PDqSsvXCvM=";
    };

    projectFile = "Shoko.CLI/Shoko.CLI.csproj";
    nugetDeps = ./shoko-deps.json;

    dotnet-sdk = dotnetCorePackages.sdk_10_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;
    runtimeId = "osx-x64";
    selfContainedBuild = true;

    executables = [];

    installPhase = ''
      runHook preInstall
      dotnet publish Shoko.CLI/Shoko.CLI.csproj \
        -c Release -r osx-x64 --self-contained true --no-restore \
        -p:ContinuousIntegrationBuild=true -p:Deterministic=true \
        -o "$out/lib/shoko-server"

      mkdir -p $out/bin

      cat > $out/bin/Shoko.CLI <<'EOF'
#!/bin/sh
set -e
data="''${SHOKO_HOME:-$HOME/.shoko/Shoko.CLI}"
server="$data/server-@version@"
if [ ! -x "$server/Shoko.CLI" ]; then
  mkdir -p "$data"
  rm -rf "$server.tmp"
  cp -R "@out@/lib/shoko-server" "$server.tmp"
  chmod -R u+w "$server.tmp"
  mv "$server.tmp" "$server"
fi
export SHOKO_HOME="$data"
export PATH="@path@:$PATH"
exec "$server/Shoko.CLI" "$@"
EOF

      substituteInPlace $out/bin/Shoko.CLI \
        --subst-var-by out $out \
        --subst-var-by version ${version} \
        --subst-var-by path ${lib.makeBinPath [mediainfo]}
      chmod 0755 $out/bin/Shoko.CLI

      runHook postInstall
    '';

    postPatch = ''
      for project in Shoko.Server/Shoko.Server.csproj Shoko.CLI/Shoko.CLI.csproj; do
        substituteInPlace "$project" \
          --replace-fail '<RuntimeIdentifiers>win-x64;linux-x64</RuntimeIdentifiers>' \
          '<RuntimeIdentifiers>osx-x64</RuntimeIdentifiers>'
      done
    '';

    meta = {
      homepage = "https://shokoanime.com";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-darwin"];
      mainProgram = "Shoko.CLI";
    };
  }
