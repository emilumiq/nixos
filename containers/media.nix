{ pkgs, config, ... }:

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
        "/home/emily/containers/jellyfin:/config"
        "/home/emily/data/Media:/media"
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
        "/home/emily/containers/qbittorrent:/config"
        "/home/emily/data/Download:/downloads"
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
        "/home/emily/containers/jackett:/config"
        "/home/emily/data/Download:/downloads"
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
        "/home/emily/containers/radarr:/config"
        "/home/emily/data/Download:/downloads"
        "/home/emily/data/Media:/media"
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
        "/home/emily/containers/sonarr:/config"
        "/home/emily/data/Download:/downloads"
        "/home/emily/data/Media:/media"
      ];
      environment = {
        TZ = "Europe/Chisinau";
      };
    };
  };
}
