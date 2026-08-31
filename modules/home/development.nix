{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    opencode
    vscode-fhs
  ];

  programs.git = {
    enable = true;
    settings = {
      credential.helper = "store";
    };
  };
}
