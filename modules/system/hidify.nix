{ pkgs, ... }:
let
  hiddify-extracted = pkgs.appimageTools.extract {
    pname = "hiddify";
    version = "4.1.1";
    src = pkgs.fetchurl {
      url = "https://github.com/hiddify/hiddify-app/releases/download/v4.1.1/Hiddify-Linux-x64-AppImage.AppImage";
      hash = "sha256-6yu2wIlxuY4tCgH8W2R+KboXsWYRScyfl+2g53v1vcM=";
    };
  };

  hiddify-fhs = pkgs.buildFHSEnv {
    name = "hiddify";
    unshareUser = false;
    unshareNet = false;
    targetPkgs = pkgs: with pkgs; [
      glib
      gtk3
      cairo
      pango
      gdk-pixbuf
      harfbuzz
      freetype
      fontconfig
      libxkbcommon
      atk
      
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libxcursor
      libxi
      libxtst
      libxrender
      libXScrnSaver
      
      curl
      openssl
      zlib
      util-linux
      nss
      nspr
      expat
      mesa
      libdrm
      
      gsettings-desktop-schemas
      adwaita-icon-theme
      libayatana-appindicator
      libayatana-indicator
      ayatana-ido
      libdbusmenu-gtk3
      libepoxy
      stdenv.cc.cc.lib
      libdbusmenu
      libglvnd
      wayland
    ];
    runScript = "${hiddify-extracted}/hiddify";
  };

  hiddify = pkgs.symlinkJoin {
    name = "hiddify";
    paths = [ hiddify-fhs ];
    postBuild = ''
      mkdir -p $out/share/applications
      mkdir -p $out/share/icons/hicolor/512x512/apps

      cp ${hiddify-extracted}/hiddify.png $out/share/icons/hicolor/512x512/apps/hiddify.png
      cp ${hiddify-extracted}/hiddify.desktop $out/share/applications/hiddify.desktop

      substituteInPlace $out/share/applications/hiddify.desktop \
        --replace "Icon=hiddify" "Icon=$out/share/icons/hicolor/512x512/apps/hiddify.png" \
        --replace "Exec=" "Exec=$out/bin/"
    '';
  };
in
{
  environment.systemPackages = [
    hiddify
  ];

  networking.firewall.trustedInterfaces = [ "tun0" "hiddify0" ];
}