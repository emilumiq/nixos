{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./media.nix
  ];

  virtualisation.oci-containers.backend = "podman";

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  systemd.services."podman-network-media" = {
    path = [pkgs.podman];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = ["multi-user.target"];
    script = ''
      podman network exists media || podman network create media
    '';
  };
}
