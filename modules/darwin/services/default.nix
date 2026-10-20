{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.emily.services;
  user = "emily";
  group = "staff";
  appSupport = "/Users/emily/Library/Application Support";
  logDir = "/Users/emily/Library/Logs/media-stack";

  suwayomi = pkgs.callPackage ../../../packages/suwayomi-server.nix {};
  anibridge = pkgs.callPackage ../../../packages/anibridge.nix {
    frontend = pkgs.callPackage ../../../packages/anibridge-frontend.nix {};
  };
  vuetorrent = pkgs.callPackage ../../../packages/vuetorrent.nix {};
  shoko = pkgs.callPackage ../../../packages/shoko-server.nix {};
  qbittorrent = pkgs.qbittorrent.override {
    guiSupport = false;
    trackerSearch = false;
  };

  daemon = name: {
    command ? null,
    script ? null,
    environment ? {},
    workingDirectory ? "/Users/emily",
  }: let
    serviceConfig = {
      Label = "com.emily.${name}";
      UserName = user;
      GroupName = group;
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = workingDirectory;
      StandardOutPath = "${logDir}/${name}.log";
      StandardErrorPath = "${logDir}/${name}.err.log";
      EnvironmentVariables =
        {
          HOME = "/Users/emily";
          TZ = "Europe/Chisinau";
          PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
        }
        // environment;
      ProcessType = "Background";
      ThrottleInterval = 10;
    };
    commandAttrs = lib.optionalAttrs (command != null) {inherit command;};
    scriptAttrs = lib.optionalAttrs (script != null) {inherit script;};
  in {
    ${name} =
      commandAttrs
      // scriptAttrs
      // {inherit serviceConfig;};
  };
in {
  options.emily.services = {
    enable = lib.mkEnableOption "Emily's native media stack";

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/Volumes/HDD/Media";
    };

    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/Volumes/HDD/Download";
    };

    incompleteDir = lib.mkOption {
      type = lib.types.str;
      default = "/Users/emily/Downloads/incomplete";
    };

    jellyfin.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    sonarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    radarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    qbittorrent.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    suwayomi.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    anibridge.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    shoko.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.media-stack-dirs.text = ''
      install -d -o ${user} -g ${group} "${logDir}"
      install -d -o ${user} -g ${group} "${appSupport}/jellyfin/cache"
      install -d -o ${user} -g ${group} "${appSupport}/anibridge"
      install -d -o ${user} -g ${group} "${appSupport}/ShokoServer"
      install -d -o ${user} -g ${group} "${cfg.incompleteDir}"
    '';

    launchd.daemons = lib.mkMerge [
      (lib.mkIf cfg.jellyfin.enable (daemon "media-jellyfin" {
        script = ''
          exec ${pkgs.jellyfin}/bin/jellyfin \
            --datadir "${appSupport}/jellyfin/data" \
            --configdir "${appSupport}/jellyfin" \
            --cachedir "${appSupport}/jellyfin/cache" \
            --logdir "${logDir}/jellyfin"
        '';
      }))
      (lib.mkIf cfg.sonarr.enable (daemon "media-sonarr" {
        script = ''
          exec ${pkgs.sonarr}/bin/Sonarr -data="${appSupport}/Sonarr" -nobrowser
        '';
      }))
      (lib.mkIf cfg.radarr.enable (daemon "media-radarr" {
        script = ''
          exec ${pkgs.radarr}/bin/Radarr -data="${appSupport}/Radarr" -nobrowser
        '';
      }))
      (lib.mkIf cfg.qbittorrent.enable (daemon "media-qbittorrent" {
        script = ''
          while [ ! -d "${cfg.downloadDir}" ]; do sleep 5; done
          profile="${appSupport}/qBittorrent"
          conf="$profile/qBittorrent/config/qBittorrent.ini"
          data="$profile/qBittorrent/data"
          seed="$profile/qBittorrent.conf"
          if [ ! -f "$conf" ] && [ -f "$seed" ]; then
            mkdir -p "$(dirname "$conf")" "$data"
            cp "$seed" "$conf"
            for item in categories.json watched_folders.json rss; do
              [ -e "$profile/$item" ] && cp -R "$profile/$item" "$(dirname "$conf")/"
            done
            [ -d "$profile/BT_backup" ] && cp -R "$profile/BT_backup" "$data/"
            [ -f "$profile/qBittorrent-data.conf" ] \
              && cp "$profile/qBittorrent-data.conf" "$(dirname "$conf")/qBittorrent-data.ini"
          fi
          if [ -f "$conf" ]; then
            ${pkgs.gawk}/bin/awk -v root="${vuetorrent}" '
              $0 == "[Preferences]" {
                print
                print "WebUI\\RootFolder=" root
                print "WebUI\\AlternativeUIEnabled=true"
                prefs = 1
                next
              }
              /^\[/ { prefs = 0 }
              prefs && /^WebUI\\RootFolder=/ { next }
              prefs && /^WebUI\\AlternativeUIEnabled=/ { next }
              { print }
            ' "$conf" > "$conf.new" && mv "$conf.new" "$conf"
          fi
          exec ${qbittorrent}/bin/qbittorrent-nox \
            --profile="$profile" \
            --webui-port=8080 \
            --confirm-legal-notice
        '';
      }))
      (lib.mkIf cfg.suwayomi.enable (daemon "media-suwayomi" {
        command = "${suwayomi}/bin/suwayomi-server";
        environment = {
          SUWAYOMI_ROOT = "${appSupport}/Tachidesk";
        };
      }))
      (lib.mkIf cfg.anibridge.enable (daemon "media-anibridge" {
        command = "${anibridge}/bin/anibridge";
        environment = {
          AB_DATA_PATH = "${appSupport}/anibridge";
          ANIBRIDGE_VENV = "${appSupport}/anibridge/venv";
        };
      }))
      (lib.mkIf cfg.shoko.enable (daemon "media-shoko" {
        command = "${shoko}/bin/Shoko.CLI";
        environment = {
          SHOKO_HOME = "${appSupport}/ShokoServer";
        };
      }))
    ];
  };
}
