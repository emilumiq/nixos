{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  isGnome = osConfig.desktop.environment == "gnome";
  custom = {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Terminal new tab";
      command = "ptyxis";
      binding = "<Super>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Terminal new window";
      command = "ptyxis --new-window";
      binding = "<Super><Shift>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Files";
      command = "nautilus --new-window";
      binding = "<Super>e";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name = "Launcher";
      command = "vicinae toggle";
      binding = "<Super>d";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      name = "Browser";
      command = "helium-wl";
      binding = "<Super>b";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      name = "Power menu";
      command = "gnome-session-quit --power-off";
      binding = "<Control><Alt>q";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
      name = "Force kill window";
      command = "gnome-force-kill";
      binding = "<Super><Shift>q";
    };
  };
in {
  config = lib.mkIf isGnome {
    home.packages = with pkgs; [gnome-session];
    home.file.".local/bin/gnome-force-kill" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -eu
        pid=$(${pkgs.glib}/bin/gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval "global.display.focus_window.get_pid()" | ${pkgs.gnugrep}/bin/grep -o "[0-9]*" | ${pkgs.coreutils}/bin/head -n1)
        if [ -n "$pid" ]; then kill -9 "$pid"; fi
      '';
    };
    dconf.settings =
      custom
      // {
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
          ];
          screensaver = ["<Super>l"];
        };
        "org/gnome/desktop/wm/keybindings" = {
          close = ["<Super>q"];
          switch-to-workspace-1 = ["<Super>1"];
          switch-to-workspace-2 = ["<Super>2"];
          switch-to-workspace-3 = ["<Super>3"];
          switch-to-workspace-4 = ["<Super>4"];
          switch-to-workspace-5 = ["<Super>5"];
          move-to-workspace-1 = ["<Super><Alt>1"];
          move-to-workspace-2 = ["<Super><Alt>2"];
          move-to-workspace-3 = ["<Super><Alt>3"];
          move-to-workspace-4 = ["<Super><Alt>4"];
          move-to-workspace-5 = ["<Super><Alt>5"];
        };
        "org/gnome/mutter" = {
          overlay-key = "Super_L";
        };
        "org/gnome/shell/keybindings" = {
          toggle-overview = ["F13"];
          switch-to-application-1 = [];
          switch-to-application-2 = [];
          switch-to-application-3 = [];
          switch-to-application-4 = [];
          switch-to-application-5 = [];
        };
      };
  };
}
