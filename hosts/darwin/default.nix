{
  lib,
  ...
}: {
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/bluetooth.nix
    ../../modules/darwin/services
  ];

  networking.hostName = "hackintosh";
  networking.computerName = "hackintosh";
  networking.localHostName = "hackintosh";

  system.primaryUser = "emily";
  system.stateVersion = 6;
  system.checks.verifyNixPath = false;

  emily.services.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-darwin";
}
