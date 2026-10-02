{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}: let
  isNiri = osConfig.desktop.environment == "niri";
  wallpaper =
    if osConfig.desktop.wallpaper == null
    then null
    else toString osConfig.desktop.wallpaper;
  avatarPng = toString ../../../assets/avatar.png;
  hyprlockAvatar = pkgs.writeShellScriptBin "hyprlock-avatar" ''
    ICON=$(busctl get-property org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User IconFile 2>/dev/null | cut -d'"' -f2)
    if [ -z "$ICON" ] || [ ! -f "$ICON" ]; then
      ICON=${avatarPng}
    fi
    RUNTIME="''${XDG_RUNTIME_DIR:-/tmp}/hyprlock-avatar.conf"
    sed "s|@AVATAR@|$ICON|" "$HOME/.config/hypr/hyprlock.conf" > "$RUNTIME"
    exec hyprlock -c "$RUNTIME"
  '';
in {
  config = lib.mkIf isNiri {
    home.packages = with pkgs; [jq hyprlock hyprlockAvatar];
    xdg.configFile."wlogout/layout".text = lib.concatMapStringsSep "\n" (x: builtins.toJSON x) [
      {
        label = "lock";
        action = "hyprlock-avatar";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "niri msg action quit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];
    programs.fish.loginShellInit = ''
      if status is-interactive; and test -z "$DISPLAY$WAYLAND_DISPLAY$SWAYSOCK"; and test -z "$SSH_TTY$SSH_CONNECTION"; and test (tty) = /dev/tty1
        exec niri-session
      end
    '';
    xdg.userDirs = {
      enable = true;
      pictures = "${config.home.homeDirectory}/Pictures";
      createDirectories = true;
    };
    home.file.".local/bin/niri-force-kill" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        set -eu
        pid=$(${pkgs.niri}/bin/niri msg --json windows | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused) | .pid')
        if [ -n "$pid" ] && [ "$pid" != "null" ]; then kill -9 "$pid"; fi
      '';
    };
    programs.niri.settings = {
      input.keyboard.xkb = {
        layout = "us,ru";
        options = "grp:win_space_toggle";
      };
      layout = {
        gaps = 8;
        border.width = 2;
        focus-ring.width = 2;
      };
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      window-rules = let
        dialogs = [
          {title = "^(Open File|Save File|Save As|Select Folder|Choose Folder|Upload|Picture.in.Picture|Developer Tools|DevTools|Task Manager|Cast.*|Select a certificate.*|.*[Dd]ialog)$";}
          {
            app-id = "^org.telegram.desktop$";
            title = ".*(Media|Viewer|Call|Player|Webview).*";
          }
          {app-id = "^xdg-desktop-portal-.*$";}
        ];
      in [
        {
          excludes = dialogs;
          open-maximized = true;
        }
        {
          matches = dialogs;
          open-floating = true;
          default-column-width = {fixed = 800;};
          default-window-height = {fixed = 800;};
        }
      ];
      binds = let
        ws = n: {
          "Mod+${toString n}".action.focus-workspace = n;
          "Mod+Alt+${toString n}".action.move-window-to-workspace = n;
        };
      in
        {
          "Mod+T".action.spawn = ["ghostty"];
          "Mod+E".action.spawn = ["nautilus" "--new-window"];
          "Mod+D".action.spawn = ["vicinae" "toggle"];
          "Mod+Tab".action.toggle-overview = [];
          "Mod+Left".action.focus-column-left-or-last = [];
          "Mod+Right".action.focus-column-right-or-first = [];
          "Mod+Up".action.focus-window-up = [];
          "Mod+Down".action.focus-window-down = [];
          "Mod+WheelScrollUp".action.focus-workspace-up = [];
          "Mod+WheelScrollDown".action.focus-workspace-down = [];
          "Mod+Shift+WheelScrollUp".action.focus-window-up = [];
          "Mod+Shift+WheelScrollDown".action.focus-window-down = [];
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";
          "F13".action.spawn = ["vicinae" "toggle"];
          "Mod+F".action.spawn = ["sh" "-c" "niri msg action toggle-window-floating && niri msg action set-column-width 800 && niri msg action set-window-height 800"];
          "Mod+M".action.toggle-windowed-fullscreen = [];
          "Mod+Q".action.close-window = [];
          "Mod+Shift+Q".action.spawn = ["niri-force-kill"];
          "Mod+B".action.spawn = ["helium-wl"];
          "Mod+L".action.spawn = ["hyprlock-avatar"];
          "Ctrl+Alt+Delete".action.spawn = ["wlogout"];
          "Ctrl+Alt+Q".action.spawn = ["wlogout"];
          "Print".action.screenshot = [];
          "Shift+Print".action.screenshot-screen = [];
          "Alt+Print".action.screenshot-window = [];
          "XF86AudioRaiseVolume".action.spawn = ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+; vol-popup"];
          "XF86AudioLowerVolume".action.spawn = ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-; vol-popup"];
          "XF86AudioMute".action.spawn = ["sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; vol-popup"];
          "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "5%+"];
          "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
        }
        // ws 1
        // ws 2
        // ws 3
        // ws 4
        // ws 5;
      spawn-at-startup = [
        {command = ["vicinae" "server"];}
      ];
    };
    xdg.configFile."hypr/hyprlock.conf".text = ''
      general {
          grace = 1
          fractional_scaling = 2
          immediate_render = true
      }

      background {
          monitor =
          path = ${wallpaper}
          color = rgb(11, 15, 16)

          blur_size = 3
          blur_passes = 2
          noise = 0.0117
          contrast = 1.3000
          brightness = 0.8000
          vibrancy = 0.2100
          vibrancy_darkness = 0.0
      }

      label {
          monitor =
          text = cmd[update:1000] echo "$(date +"%I:%M %p")"
          color = rgb(94, 141, 135)
          font_size = 160
          font_family = JetBrainsMono Nerd Font
          position = 0, -133
          halign = center
          valign = top
      }

      label {
          monitor =
          text = $USER
          color = rgb(197, 200, 201)
          font_size = 48
          font_family = JetBrainsMono Nerd Font
          position = 0, 300
          halign = center
          valign = bottom
      }

      image {
          monitor =
          path = @AVATAR@
          size = 160
          rounding = -1
          border_size = 0
          rotate = 0
          reload_time = -1
          position = 0, 400
          halign = center
          valign = bottom
      }

      input-field {
          monitor =
          size = 300, 90
          outline_thickness = 2
          dots_size = 0.2
          dots_spacing = 0.2
          dots_center = true
          outer_color = rgb(94, 141, 135)
          inner_color = rgba(16, 20, 21, 0.6)
          font_color = rgb(197, 200, 201)
          fade_on_empty = false
          font_family = JetBrainsMono Nerd Font
          placeholder_text = <i>Type password</i>
          hide_input = false
          position = 0, 100
          halign = center
          valign = bottom
      }

      label {
          monitor =
          text = $LAYOUT
          color = rgb(94, 141, 135)
          font_size = 19
          font_family = JetBrainsMono Nerd Font
          position = 0, 53
          halign = center
          valign = bottom
      }

      label {
          monitor =
          text = cmd[update:60000] echo "<b>$(uptime -p)</b>"
          color = rgb(94, 141, 135)
          font_size = 32
          font_family = JetBrainsMono Nerd Font
          position = 0, 0
          halign = right
          valign = bottom
      }
    '';
    services.mako = {
      enable = false;
    };
    systemd.user.services.swaybg = lib.mkIf (wallpaper != null) {
      Unit = {
        Description = "Wallpaper";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i %h/.config/wallpaper/current -m fill";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
    xdg.configFile."wallpaper/current".source = lib.mkIf (wallpaper != null) osConfig.desktop.wallpaper;
  };
}
