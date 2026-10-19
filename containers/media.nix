{
  pkgs,
  config,
  ...
}: let
  userHome = config.users.users.emily.home;
  mediaNet = "media";
  netOpt = ["--network=${mediaNet}"];
  dataDep = {
    after = ["home-emily-data.mount" "podman-network-media.service"];
    requires = ["home-emily-data.mount"];
    wants = ["podman-network-media.service"];
  };
in {
  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      autoStart = true;
      ports = ["8096:8096"];
      extraOptions =
        netOpt
        ++ [
          "--device=/dev/dri:/dev/dri"
        ];
      volumes = [
        "${userHome}/containers/jellyfin:/config"
        "${userHome}/data/Media:/media"
      ];
      environment = {
        TZ = "Europe/Chisinau";
        PUID = "1000";
        PGID = "100";
      };
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      autoStart = true;
      dependsOn = ["gluetun"];
      extraOptions = [
        "--network=container:gluetun"
      ];
      volumes = [
        "${userHome}/containers/qbittorrent:/config"
        "${userHome}/containers/qbittorrent/incomplete:/incomplete"
        "${userHome}/data/Download:/downloads"
      ];
      environment = {
        TZ = "Europe/Chisinau";
        WEBUI_PORT = "8080";
        PUID = "1000";
        PGID = "100";
        DOCKER_MODS = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
      };
    };

    gluetun = {
      image = "ghcr.io/qdm12/gluetun:latest";
      autoStart = true;
      ports = ["8080:8080"];
      extraOptions =
        netOpt
        ++ [
          "--cap-add=NET_ADMIN"
        ];
      environmentFiles = [
        "${userHome}/containers/gluetun.env"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    jackett = {
      image = "lscr.io/linuxserver/jackett:latest";
      autoStart = true;
      ports = ["9117:9117"];
      extraOptions = netOpt;
      volumes = [
        "${userHome}/containers/jackett:/config"
        "${userHome}/data/Download:/downloads"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    trawl = {
      image = "ghcr.io/germondai/trawl:latest";
      autoStart = true;
      ports = ["8191:8191"];
      extraOptions = netOpt;
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      autoStart = true;
      ports = ["7878:7878"];
      extraOptions = netOpt;
      volumes = [
        "${userHome}/containers/radarr:/config"
        "${userHome}/data/Download:/downloads"
        "${userHome}/data/Media:/media"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      autoStart = true;
      ports = ["8989:8989"];
      extraOptions = netOpt;
      volumes = [
        "${userHome}/containers/sonarr:/config"
        "${userHome}/data/Download:/downloads"
        "${userHome}/data/Media:/media"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    anibridge = {
      image = "ghcr.io/anibridge/anibridge:latest";
      autoStart = true;
      ports = ["4848:4848"];
      extraOptions = netOpt;
      volumes = [
        "${userHome}/containers/anibridge:/config"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "Europe/Chisinau";
      };
    };

    suwayomi = {
      image = "ghcr.io/suwayomi/tachidesk:latest";
      autoStart = true;
      ports = ["4567:4567"];
      extraOptions = netOpt;
      volumes = [
        "${userHome}/containers/suwayomi:/home/suwayomi/.local/share/Tachidesk"
      ];
      environment = {
        TZ = "Europe/Chisinau";
        PUID = "1000";
        PGID = "100";
      };
    };

    shoko = {
      image = "ghcr.io/shokoanime/server:latest";
      autoStart = true;
      ports = ["8111:8111"];
      extraOptions = netOpt;
      volumes = [
        "${userHome}/containers/shoko:/home/shoko/.shoko/Shoko.CLI"
        "${userHome}/data/Media:/media:ro"
      ];
      environment = {
        TZ = "Europe/Chisinau";
        PUID = "1000";
        PGID = "100";
      };
    };
  };
  systemd.services = {
    podman-jellyfin = dataDep;
    podman-qbittorrent = dataDep;
    podman-gluetun = dataDep;
    podman-jackett = dataDep;
    podman-trawl = dataDep;
    podman-radarr = dataDep;
    podman-sonarr = dataDep;
    podman-anibridge = dataDep;
    podman-suwayomi = dataDep;
    podman-shoko = dataDep;
  };
}
