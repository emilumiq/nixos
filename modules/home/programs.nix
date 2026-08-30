{ pkgs, inputs, ... }:

{
  home.packages = (with pkgs; [
    gnome-text-editor
  	loupe
  	ptyxis
  	celluloid
  	telegram-desktop
  ]) ++ [
  	inputs.helium.packages.${pkgs.system}.default
  ];
}
