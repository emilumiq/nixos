{ pkgs, config, ... }:

let
  dataDep = {
    after = [ "home-emily-data.mount" ];
    requires = [ "home-emily-data.mount" ];
  };
in
{
  virtualisation.oci-containers.containers = {
    jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      autoStart = true;
      ports = [ "8096:8096" ];
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
      ];
      volumes = [
        "$HOME/containers/jellyfin:/config"
        "$HOME/data/Media:/media"
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
      ports = [
        "8080:8080"
        "6881:6881"
        "6881:6881/udp"
      ];
      volumes = [
        "$HOME/containers/qbittorrent:/config"
        "$HOME/data/Download:/downloads"
      ];
      environment = {
        TZ = "Europe/Chisinau";
        WEBUI_PORT = "8080";
        PUID = "1000";
        PGID = "100";
        DOCKER_MODS = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
      };
    };
    
    jackett = {
      image = "lscr.io/linuxserver/jackett:latest";
      autoStart = true;
      ports = [ "9117:9117" ];
      volumes = [
        "$HOME/containers/jackett:/config"
        "$HOME/data/Download:/downloads"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };
    
    trawl = {
      image = "ghcr.io/germondai/trawl:latest";
      autoStart = true;
      ports = [ "8191:8191" ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      autoStart = true;
      ports = [ "7878:7878" ];
      volumes = [
        "$HOME/containers/radarr:/config"
        "$HOME/data/Download:/downloads"
        "$HOME/data/Media:/media"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      autoStart = true;
      ports = [ "8989:8989" ];
      volumes = [
        "$HOME/containers/sonarr:/config"
        "$HOME/data/Download:/downloads"
        "$HOME/data/Media:/media"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };

    anibridge = {
      image = "ghcr.io/anibridge/anibridge:latest";
      autoStart = true;
      ports = [ "4848:4848" ];
      volumes = [
        "$HOME/containers/anibridge:/config"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "Europe/Chisinau";
      };
    };
  };

  systemd.services = {
    podman-jellyfin = dataDep;
    podman-qbittorrent = dataDep;
    podman-jackett = dataDep;
    podman-radarr = dataDep;
    podman-sonarr = dataDep;
    podman-anibridge = dataDep;
  };
}