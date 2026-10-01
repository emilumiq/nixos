{pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      background-opacity = 0.95;
      window-padding-x = 8;
      window-padding-y = 8;
      confirm-close-surface = false;
      gtk-single-instance = true;
      keybind = [
        "ctrl+t=new_tab"
        "ctrl+q=close_tab"
      ];
      background = "1e1e2e";
      foreground = "cdd6f4";
      cursor-color = "f5e0dc";
      selection-background = "585b70";
      selection-foreground = "cdd6f4";
      palette = [
        "0=#45475a"
        "1=#f38ba8"
        "2=#a6e3a1"
        "3=#f9e2af"
        "4=#89b4fa"
        "5=#cba6f7"
        "6=#94e2d5"
        "7=#bac2de"
        "8=#585b70"
        "9=#f38ba8"
        "10=#a6e3a1"
        "11=#f9e2af"
        "12=#89b4fa"
        "13=#cba6f7"
        "14=#94e2d5"
        "15=#a6adc8"
      ];
    };
  };
}
