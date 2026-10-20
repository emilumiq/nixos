{
  pkgs,
  lib,
  ...
}: {
  nix = {
    enable = true;
    package = pkgs.lix;

    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "emily"];
      substituters = [
        "https://cache.nixos.org"
        "https://cache.lix.systems"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      ];
      connect-timeout = 10;
      fallback = true;
    };

    gc = {
      automatic = true;
      interval = [{Weekday = 7; Hour = 3; Minute = 15;}];
      options = "--delete-older-than 14d";
    };

    optimise.automatic = true;
  };

  # nix-darwin only updates the shell of users it manages, so the existing
  # macOS account has to be listed here (with its current UID) as well.
  users.knownUsers = ["emily"];

  users.users.emily = {
    uid = 501;
    home = "/Users/emily";
    shell = pkgs.fish;
    description = "Emily";
  };

  programs.fish.enable = true;

  environment.shells = [pkgs.fish];

  environment.variables = {
    NH_FLAKE = "/Users/emily/dotfiles";
    EDITOR = "micro";
    VISUAL = "micro";
    TZ = "Europe/Chisinau";
  };

  environment.systemPackages = with pkgs; [
    micro
    git
    fish
    starship
    curl
    wget
    jq
    ripgrep
    unzip
    nh
    just
    alejandra
  ];
}
