{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop.environment;
in {
  config = lib.mkIf (cfg == "niri") {
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri;
    services.udisks2.enable = true;
    services.gnome.gnome-keyring.enable = true;
    fonts.packages = with pkgs; [nerd-fonts.iosevka];
    environment.systemPackages = with pkgs; [
      ghostty
      nautilus
      seahorse
      gnome-control-center
      overskride
      gvfs
      udisks
      xwayland-satellite
      swaylock-effects
      swaybg
      wlogout
      brightnessctl
      wireplumber
      wl-clipboard
    ];
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gnome];
    };
  };
}
