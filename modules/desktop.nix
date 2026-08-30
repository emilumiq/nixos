{ pkgs, lib, ... }:

{
  services.xserver = {
    enable = true;
    excludePackages = [ pkgs.xterm ];
    xkb = {
      layout = "us,ru";
      options = "grp:win_space_toggle";
    };
  };
  
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.dbus.enable = true;
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

  services.flatpak.enable = lib.mkForce false;

  documentation = {
  	enable = false;
  	doc.enable = false;
  	man.enable = false;
  	info.enable = false;
  };
  
  hardware.graphics = {
  	enable = true;

  	extraPackages = with pkgs; [
  	  vulkan-loader
  	  vulkan-tools
  	  mesa.opencl
  	  libva-utils
  	];
  };
  
  environment.systemPackages = with pkgs; [
  	gnome-shell
  	gnome-tweaks
  	gnome-extension-manager
  	nautilus
  	gnome-control-center

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

  programs.dconf.enable = true;
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
}
