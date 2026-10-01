{pkgs, ...}: {
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.substituters = ["https://nix-community.cachix.org"];
  nix.settings.trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  nix.package = pkgs.lix;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [nh git micro just exfatprogs ntfs3g unzip];
  environment.variables.NH_FLAKE = "/home/emily/dotfiles";
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults lecture = never
    '';
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  system.stateVersion = "26.05";
}
