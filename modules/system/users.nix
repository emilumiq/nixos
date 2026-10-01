{
  config,
  pkgs,
  lib,
  ...
}: let
  avatar = let
    p = toString ../../assets + "/avatar.png";
  in
    if builtins.pathExists p
    then p
    else null;
in {
  systemd.tmpfiles.rules = lib.optional (avatar != null) "L+ /var/lib/AccountsService/icons/emily - - - - ${avatar}";
  services.accounts-daemon.enable = true;
  systemd.services.accounts-avatar = lib.mkIf (avatar != null) {
    description = "Set declarative user avatar";
    wantedBy = ["multi-user.target"];
    before = ["accounts-daemon.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /var/lib/AccountsService/users
      printf '[User]\nIcon=/var/lib/AccountsService/icons/emily\n' > /var/lib/AccountsService/users/emily
    '';
  };
  users.users.emily = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
    hashedPassword = "$6$Ha.YMvf.o4CGhhkO$NgdLisytbvuIJdo/wE0R/r6MVedXOWFAnjkgUZ9GzEzJaVqXReXsRtIByGRRKob/h6yQ.9WF/UKtmuT2JvKZp1";
    shell = pkgs.fish;
    description = "Emily 🌺🐚";
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };
  services.displayManager.autoLogin = lib.mkIf (config.desktop.environment == "gnome") {
    enable = true;
    user = "emily";
  };
  services.getty.autologinUser = lib.mkIf (config.desktop.environment == "niri") "emily";
  home-manager.backupFileExtension = "backup";
}
