{
  pkgs,
  inputs,
  ...
}: let
  heliumPkg = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
  helium-wl = pkgs.writeShellScriptBin "helium-wl" ''
    if [ -z "''${WAYLAND_DISPLAY:-}" ] && [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      for s in "$XDG_RUNTIME_DIR"/wayland-*; do
        case "$s" in
          *.lock) continue ;;
        esac
        if [ -S "$s" ]; then
          WAYLAND_DISPLAY="$(basename "$s")"
          export WAYLAND_DISPLAY
          break
        fi
      done
    fi
    if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ "''${XDG_SESSION_TYPE:-}" != "wayland" ]; then
      export XDG_SESSION_TYPE=wayland
    fi
    exec ${heliumPkg}/bin/helium --ozone-platform-hint=auto "$@"
  '';
in {
  home.packages = [helium-wl];
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "helium.desktop";
      "x-scheme-handler/http" = "helium.desktop";
      "x-scheme-handler/https" = "helium.desktop";
    };
  };
}
