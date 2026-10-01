{...}: {
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nix"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/containers"
      "/var/lib/AccountsService"
      "/var/lib/tailscale"
      "/var/lib/bluetooth"
      "/home/emily"
    ];
    files = ["/etc/machine-id"];
  };
}
