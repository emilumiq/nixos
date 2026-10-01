{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}: let
  isNiri = osConfig.desktop.environment == "niri";

  ewwOpen = pkgs.writeShellScriptBin "eww-open" ''
    for _ in $(seq 1 15); do
      timeout 3 eww active-windows >/dev/null 2>&1 && break
      sleep 1
    done
  '';

  svcPath = lib.makeBinPath ([
      pkgs.eww
      pkgs.wireplumber
      pkgs.coreutils
      pkgs.gnused
      pkgs.gawk
      pkgs.gnugrep
      pkgs.procps
    ]
    ++ config.emily.eww.bins);

  yuck = ''
    (defpoll time :interval "1s" "date '+%H:%M'")

    (include "./widgets/volume.yuck")
    (include "./widgets/player.yuck")
    (include "./widgets/notifs.yuck")
    (include "./windows.yuck")
  '';

  windowsYuck = ''
    (defwindow volume
      :monitor 0
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "eww-volume"
      :geometry (geometry :y "20px" :width "200px" :anchor "bottom center")
      (volume-popup))

    (defwindow player
      :monitor 0
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "eww-player"
      :geometry (geometry :x "20px" :y "20px" :anchor "bottom right")
      (player-widget))

    (defwindow notifs
      :monitor 0
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "eww-notifs"
      :geometry (geometry :x "20px" :y "20px" :anchor "top right")
      (notif-window))
  '';

  scss =
    ''
      $bg: #0B0F10;
      $bg-alt: #101415;
      $fg: #c5c8c9;
      $fg-alt: #cccccc;
      $gray: #4c4c4c;
      $accent: #5e8d87;

      * {
        transition: 200ms;
        border: none;
        box-shadow: none;
        font-family: "Iosevka Nerd Font", "JetBrainsMono Nerd Font", monospace;
      }

      window {
        background-color: transparent;
      }
    ''
    + lib.concatStringsSep "\n" config.emily.eww.scssParts;
in {
  options.emily.eww.bins = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
    description = "Extra binaries exposed to the eww daemon and widgets.";
  };

  options.emily.eww.scssParts = lib.mkOption {
    type = lib.types.listOf lib.types.lines;
    default = [];
    description = "Extra SCSS appended to eww.scss.";
  };

  config = lib.mkIf isNiri {
    home.packages =
      [
        pkgs.eww
        pkgs.playerctl
        pkgs.adwaita-icon-theme
      ]
      ++ config.emily.eww.bins;

    xdg.configFile."eww/eww.yuck".text = yuck;
    xdg.configFile."eww/windows.yuck".text = windowsYuck;
    xdg.configFile."eww/eww.scss".text = scss;

    systemd.user.services.eww = {
      Unit = {
        Description = "eww widgets daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Environment = "PATH=${svcPath}";
        ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    systemd.user.services.eww-windows = {
      Unit = {
        Description = "Open eww windows";
        After = ["eww.service"];
        Requires = ["eww.service"];
      };
      Service = {
        Type = "oneshot";
        Environment = "PATH=${svcPath}";
        ExecStart = "${ewwOpen}/bin/eww-open";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
