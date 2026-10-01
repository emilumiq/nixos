{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./gnome.nix ./niri.nix];
  options.desktop.environment = lib.mkOption {
    type = lib.types.enum ["gnome" "niri"];
    default = "gnome";
    description = "Desktop environment to use.";
  };
  options.desktop.wallpaper = lib.mkOption {
    type = lib.types.nullOr (lib.types.either lib.types.path lib.types.str);
    default = null;
    description = "Wallpaper image path.";
  };
  config = {
    services.xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
      xkb = {
        layout = "us,ru";
        options = "grp:win_space_toggle";
      };
    };
    services.displayManager.gdm.enable = lib.mkIf (config.desktop.environment == "gnome") true;
    services.displayManager.enable = config.desktop.environment == "gnome";
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.dbus.enable = true;
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
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
    ];
    programs.dconf.enable = true;
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_TIME = "ro_RO.UTF-8";
      LC_MONETARY = "ro_RO.UTF-8";
    };
    time.timeZone = "Europe/Chisinau";
  };
}
