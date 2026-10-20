{
  description = "Emily NixOS + nix-darwin config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-darwin,
    nix-darwin,
    home-manager,
    home-manager-darwin,
    impermanence,
    ...
  } @ inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        {nixpkgs.hostPlatform = "x86_64-linux";}
        ./hosts/nixos
        impermanence.nixosModules.impermanence
        inputs.niri.nixosModules.niri
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.emily = import ./homes/emily;
        }
      ];
    };

    darwinConfigurations.hackintosh = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules = [
        {nixpkgs.hostPlatform = "x86_64-darwin";}
        ./hosts/darwin
        home-manager-darwin.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {inherit inputs;};
          home-manager.users.emily = import ./homes/emily/darwin.nix;
        }
      ];
    };

    packages.x86_64-darwin = let
      pkgs = nixpkgs-darwin.legacyPackages.x86_64-darwin;
    in {
      vuetorrent = pkgs.callPackage ./packages/vuetorrent.nix {};
      suwayomi-server = pkgs.callPackage ./packages/suwayomi-server.nix {};
      anibridge-frontend = pkgs.callPackage ./packages/anibridge-frontend.nix {};
      anibridge = pkgs.callPackage ./packages/anibridge.nix {
        frontend = pkgs.callPackage ./packages/anibridge-frontend.nix {};
      };
      jellyfin = pkgs.jellyfin;
      sonarr = pkgs.sonarr;
      radarr = pkgs.radarr;
      qbittorrent-nox = pkgs.qbittorrent.override {
        guiSupport = false;
        trackerSearch = false;
      };
      dotnet-sdk = pkgs.dotnet-sdk_10;
      nuget-to-json = pkgs.nuget-to-json;
      shoko-server = pkgs.callPackage ./packages/shoko-server.nix {};
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    formatter.x86_64-darwin = nixpkgs-darwin.legacyPackages.x86_64-darwin.alejandra;

    devShells.x86_64-linux.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
      pkgs.mkShell {
        packages = with pkgs; [nh alejandra git];
        shellHook = ''
          export NH_FLAKE="$PWD"
        '';
      };

    devShells.x86_64-darwin.default = let
      pkgs = nixpkgs-darwin.legacyPackages.x86_64-darwin;
    in
      pkgs.mkShell {
        packages = with pkgs; [nh alejandra git];
        shellHook = ''
          export NH_FLAKE="$PWD"
        '';
      };
  };
}
