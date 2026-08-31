{ config, pkgs, lib, ... }:

let
  dir = ./modules/home;
  homeModules = map (name: dir + "/${name}") (builtins.attrNames (builtins.readDir dir));
in
{
  imports = homeModules;
  
  home.username = "emily";
  home.homeDirectory = "/home/emily";

  home.packages = with pkgs; [
    git
    micro
    nerd-fonts.jetbrains-mono
  ];
  
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting ""
      set -e SSH_ASKPASS
      set -e GIT_ASKPASS
    '';
  };
  
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$nodejs$python$rust$golang$nix_shell$line_break$character";
      
      nix_shell = {
        symbol = "❄️ ";
        format = "via [$symbol$state]($style) ";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };
  
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      disable-extension-version-validation = true;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "just-perfection-desktop@just-perfection"
        "clipboard-history@aayanl.tech"
      ];
    };
    
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
