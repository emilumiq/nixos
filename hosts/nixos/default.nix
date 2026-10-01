{...}: {
  imports = [
    ./hardware.nix
    ../../containers
    ../../modules/system/base.nix
    ../../modules/system/bluetooth.nix
    ../../modules/system/users.nix
    ../../modules/system/persistence.nix
    ../../modules/system/networking.nix
    ../../modules/system/keyd.nix
    ../../modules/system/sound.nix
    ../../modules/desktop
  ];
  networking.hostName = "nixos";
  desktop.environment = "niri";
  desktop.wallpaper = ../../assets/wallpapers/bloom-into-you-3.jpg;
}
