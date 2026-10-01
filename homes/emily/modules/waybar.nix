{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  isNiri = osConfig.desktop.environment == "niri";

  wsWaybar = pkgs.writeShellScriptBin "ws-waybar" ''
    query() {
      local ws out focused_out
      ws=$(niri msg --json workspaces 2>/dev/null) || return 0
      focused_out=$(echo "$ws" | jq -r '[.[] | select(.is_focused)][0].output // empty')
      [ -z "$focused_out" ] && return 0
      out=$(echo "$ws" | jq -r --arg o "$focused_out" '
        [ .[] | select(.output == $o)
          | {idx: .idx, f: .is_focused, a: (.active_window_id != null)} ]
        | unique_by(.idx) | sort_by(.idx)
        | map(if .f then "<span color=\\\"#5e8d87\\\">●</span>"
              elif .a then "<span color=\\\"#c5c8c9\\\">●</span>"
              else "<span color=\\\"#4c4c4c\\\">●</span>" end)
        | join(" ")')
      printf '{"text": "%s"}\n' "$out"
    }
    query
    while sleep 1; do query; done
  '';

  wsLayout = pkgs.writeShellScriptBin "ws-layout" ''
    kb=$(niri msg --json keyboard-layouts 2>/dev/null) || { echo "--"; exit 0; }
    name=$(echo "$kb" | jq -r '.names[.current_idx // 0] // ""')
    if echo "$name" | grep -qi russian; then echo "RU"
    elif [ -z "$name" ]; then echo "--"
    else echo "EN"
    fi
  '';

  btBatt = pkgs.writeShellScriptBin "bt-batt" ''
    devs=$(timeout 3 bluetoothctl devices 2>/dev/null)
    while IFS= read -r line; do
      addr=$(echo "$line" | grep -o '[0-9A-F:]\{17\}' | head -n 1)
      [ -z "$addr" ] && continue
      info=$(timeout 3 bluetoothctl info "$addr" 2>/dev/null)
      echo "$info" | grep -q "Connected: yes" || continue
      pct=$(echo "$info" | grep -oi "battery[^0-9]\\{0,10\\}[0-9]\\+" | grep -o "[0-9]\\+" | tail -n 1)
      [ -z "$pct" ] && continue
      name=$(echo "$info" | grep -m1 "Name:" | cut -d: -f2- | xargs)
      filled=$(( (pct + 10) / 20 ))
      [ "$filled" -gt 5 ] && filled=5
      [ "$filled" -lt 0 ] && filled=0
      bar=""
      i=0
      while [ "$i" -lt 5 ]; do
        if [ "$i" -lt "$filled" ]; then
          bar="$bar<span color=\\\"#5e8d87\\\">━</span>"
        else
          bar="$bar<span color=\\\"#4c4c4c\\\">━</span>"
        fi
        i=$((i + 1))
      done
      printf '{"text": "%s", "tooltip": "%s: %s%%"}\n' "$bar" "$name" "$pct"
      exit 0
    done <<< "$devs"
    printf '{"text": ""}\n'
  '';

  svcPath = lib.makeBinPath [
    pkgs.waybar
    pkgs.niri
    pkgs.jq
    pkgs.bluez
    pkgs.wlogout
    pkgs.gnome-control-center
    pkgs.bluez
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.gawk
    wsWaybar
    wsLayout
  ];
in {
  config = lib.mkIf isNiri {
    home.packages = [wsWaybar wsLayout btBatt];

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 32;
          output = ["DP-1" "HDMI-A-1"];
          modules-left = ["custom/workspaces" "tray"];
          modules-right = ["custom/btbattery" "bluetooth" "custom/layout" "clock" "custom/power"];
          "custom/workspaces" = {
            exec = "${wsWaybar}/bin/ws-waybar";
            return-type = "json";
            format = "{}";
          };
          tray = {
            icon-size = 18;
            spacing = 4;
          };
          bluetooth = {
            format = "󰂯";
            format-disabled = "";
            format-connected = "󰂯 {num_connections}";
            on-click = "overskride";
          };
          "custom/btbattery" = {
            exec = "${btBatt}/bin/bt-batt";
            return-type = "json";
            format = "{}";
            interval = 30;
          };
          "custom/layout" = {
            exec = "${wsLayout}/bin/ws-layout";
            interval = 1;
            format = "{}";
          };
          clock = {
            format = "{:%H:%M}";
          };
          "custom/power" = {
            format = "⏻";
            on-click = "wlogout";
            tooltip = false;
          };
        };
      };
      style = ''
        * {
          font-family: "Iosevka Nerd Font", "JetBrainsMono Nerd Font", monospace;
          font-size: 14px;
          border: none;
          box-shadow: none;
        }
        window#waybar {
          background-color: #0B0F10;
          color: #c5c8c9;
        }
        #custom-workspaces,
        #tray,
        #custom-btbattery,
        #bluetooth,
        #custom-layout,
        #clock,
        #custom-power {
          padding: 0 8px;
          color: #c5c8c9;
        }
        #custom-btbattery {
          font-size: 11px;
          padding: 0 2px;
        }
        #custom-layout {
          color: #5e8d87;
          font-weight: 500;
        }
        #clock {
          font-weight: 500;
        }
      '';
    };

    systemd.user.services.waybar.Service.Environment = "PATH=${svcPath}";
  };
}
