{ pkgs, config, ... }:

{
  imports = [
    ./media.nix
  ];

  virtualisation.oci-containers.backend = "podman";
}
