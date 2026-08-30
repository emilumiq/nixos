{ config, pkgs, lib, ... }:

let
  sysModulesDir = ./modules;
  sysFiles = builtins.readDir sysModulesDir;
  systemModules = map (name: sysModulesDir + "/${name}") (
  	builtins.filter (name:
      sysFiles.${name} == "regular" && lib.hasSuffix ".nix" name
  	) (builtins.attrNames sysFiles)
  );
in
{
  imports = [
   ./hardware-configuration.nix
  ] ++ systemModules;
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.grub = {
  	enable = true;
  	device = "nodev";
  	efiSupport = true;
  	useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ 
    "usbcore.autosuspend=-1" 
    "btusb.enable_autosuspend=0" 
  ];
  boot.extraModprobeConfig = ''
    options btusb reset=1
  '';
  
  networking.hostName= "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Chisinau";

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  systemd.services.bluetooth-reset = {
    description = "Reset Bluetooth Adapter on Boot";
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.util-linux}/bin/rfkill block bluetooth
      sleep 1
      ${pkgs.util-linux}/bin/rfkill unblock bluetooth
    '';
  };

  nix.package = pkgs.lix;
  programs.fish.enable = true;
  
  services.displayManager.autoLogin = {
    enable = true;
    user = "emily";
  };

  users.users.emily = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    hashedPassword = "$6$Ha.YMvf.o4CGhhkO$NgdLisytbvuIJdo/wE0R/r6MVedXOWFAnjkgUZ9GzEzJaVqXReXsRtIByGRRKob/h6yQ.9WF/UKtmuT2JvKZp1";
    shell = pkgs.fish;
    description = "Emily 🌺🐚";
  };
  home-manager.backupFileExtension = "backup";
  home-manager.users.emily = import ./home.nix;

  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nix"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/AccountsService"
      "/home/emily"
    ];
  };

  environment.systemPackages = with pkgs; [
  	nh
  ];
  environment.variables.NH_FLAKE="/home/emily/dotfiles";

  nix.gc = {
  	automatic = true;
  	dates = "weekly";
  	options = "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = true;
  
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults lecture = never
    '';
  };
  
  system.stateVersion = "26.05";
}
