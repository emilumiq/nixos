{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop.environment;
in {
  config = lib.mkIf (cfg == "gnome") {
    services.desktopManager.gnome.enable = true;
    services.gnome = {
      core-developer-tools.enable = false;
      core-os-services.enable = true;
      core-apps.enable = false;
      glib-networking.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = lib.mkForce false;
      gnome-initial-setup.enable = false;
      gnome-user-share.enable = false;
      rygel.enable = false;
    };
    environment.systemPackages = with pkgs; [
      gnome-shell
      gnome-tweaks
      gnome-extension-manager
      nautilus
      gnome-control-center
      ptyxis
      gnomeExtensions.appindicator
      gnomeExtensions.just-perfection
      gnomeExtensions.clipboard-history
    ];
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-user-docs
      orca
      evince
      geary
      epiphany
      yelp
      totem
    ];
    services.udev.packages = with pkgs; [gnome-settings-daemon];
  };
}
