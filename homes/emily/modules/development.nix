{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    opencode
    vscode-fhs
    android-studio
  ];

  programs.git = {
    enable = true;
    settings = {
      credential.helper = "store";
    };
  };
}
