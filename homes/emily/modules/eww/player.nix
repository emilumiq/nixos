{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  isNiri = osConfig.desktop.environment == "niri";

  playerListener = pkgs.writeShellScriptBin "player-listener" ''
    PATH="${pkgs.lib.makeBinPath [pkgs.playerctl pkgs.coreutils pkgs.gnused pkgs.gnugrep]}:$PATH"
    export LC_NUMERIC=C

    NO_TRACK='{"title": "No track", "artist": "Unknown", "cover": "", "duration": 100, "position": 0, "elapsed": "0:00", "remaining": "0:00"}'

    format_time() {
      local secs=$1
      [ -z "$secs" ] || [ "$secs" -lt 0 ] && secs=0
      printf "%d:%02d" $((secs / 60)) $((secs % 60))
    }

    get_player_info() {
      local player
      player=$(playerctl --list-all 2>/dev/null | xargs -I {} playerctl -p {} status -f "{} {{status}}" 2>/dev/null | grep "Playing" | cut -d' ' -f1 | head -1)

      if [ -z "$player" ]; then
        player=$(playerctl --list-all 2>/dev/null | xargs -I {} playerctl -p {} status -f "{} {{status}}" 2>/dev/null | grep "Paused" | cut -d' ' -f1 | head -1)
      fi

      if [ -z "$player" ]; then
        echo "$NO_TRACK"
        return
      fi

      local status
      status=$(playerctl -p "$player" status 2>/dev/null)
      if [ -z "$status" ] || [ "$status" = "Stopped" ]; then
        echo "$NO_TRACK"
        return
      fi

      local title artist arturl mpris_len pos
      title=$(playerctl -p "$player" metadata title 2>/dev/null)
      artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
      arturl=$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null)
      mpris_len=$(playerctl -p "$player" metadata mpris:length 2>/dev/null)
      pos=$(playerctl -p "$player" position 2>/dev/null)

      if [ -z "$title" ]; then
        echo "$NO_TRACK"
        return
      fi

      if [[ "$mpris_len" =~ ^[0-9]+$ ]]; then
        duration_secs=$((mpris_len / 1000000))
      else
        duration_secs=100
      fi
      [ "$duration_secs" -eq 0 ] && duration_secs=100

      pos_secs=$(echo "$pos" | sed 's/\..*//')
      [ -z "$pos_secs" ] && pos_secs=0

      local cover_path=""
      clean_url=$(echo "$arturl" | sed 's/file:\/\///g')
      if [ -z "$clean_url" ] || printf '%s' "$clean_url" | grep -q "[ %()'\"]"; then
        cover_path=""
      elif [ -f "$clean_url" ]; then
        cover_path="$clean_url"
      fi

      clean_title=$(echo "''${title}" | sed 's/"/\\"/g')
      clean_artist=$(echo "''${artist:-Unknown}" | sed 's/"/\\"/g')

      echo "{\"title\": \"$clean_title\", \"artist\": \"$clean_artist\", \"cover\": \"$cover_path\", \"duration\": $duration_secs, \"position\": $pos_secs, \"elapsed\": \"$(format_time $pos_secs)\", \"remaining\": \"$(format_time $((duration_secs - pos_secs)))\"}"
    }

    while true; do
      get_player_info
      sleep 1
    done
  '';

  yuck = ''
    (deflisten player
      :initial '{"title": "No track", "artist": "Unknown", "cover": "", "duration": 100, "position": 0, "elapsed": "0:00", "remaining": "0:00"}'
      "player-listener")

    (defwidget player-widget []
      (box :orientation "v" :space-evenly false :spacing 6 :valign "end"
        (revealer
          :reveal {player.title != "No track"}
          :transition "slidedown"
          :duration "200ms"
          (box :class "player_widget" :orientation "v" :space-evenly false
            (box :orientation "v" :space-evenly false
                 :style "padding: 5px 5px 10px 5px;"
              (box :orientation "h" :space-evenly false :spacing 15
                (box :class "player_cover"
                  :style "background-image: url(''${player.cover}');"
                  :width 80 :height 80)
                (box :class "player_info" :orientation "v" :space-evenly false :valign "center"
                  (label :class "player_title"  :text {player.title}  :limit-width 50 :halign "start")
                  (label :class "player_artist" :text {player.artist} :halign "start")))
              (box :class "player_progress"
                   :style "padding: 10px 0 0 0;"
                (scale :min 0 :max {player.duration} :value {player.position} :vexpand true)))
          (box :class "player_footer"
               :orientation "h"
               :space-evenly true
            (label :text {"󱎫  " + time}          :halign "start")
            (label :text {"󰓃  " + volume.device} :limit-width 50 :halign "end"))))))
  '';

  scss = ''
    .player_widget {
      background-color: $bg;
      border-radius: 6px;
      padding: 10px;

      .player_cover {
        min-width: 80px;
        min-height: 80px;
        border-radius: 6px;
        background-size: cover;
        background-color: $bg-alt;
      }

      .player_info {
        .player_title {
          font-size: 1rem;
          font-weight: bold;
          color: $fg;
        }

        .player_artist {
          font-size: 0.9rem;
          color: $fg-alt;
        }
      }

      .player_footer {
        background-color: $bg-alt;
        color: $fg-alt;
        padding: 10px;
        border-radius: 6px;
        min-width: 320px;
        font-size: 1rem;
        font-weight: bold;
      }

      .player_progress {
        scale {
          trough {
            all: unset;
            background-color: $bg-alt;
            border-radius: 6px;
            min-height: 40px;
            min-width: 320px;

            highlight {
              all: unset;
              background-color: $fg;
              border-radius: 6px;
            }
          }

          slider { all: unset; }
        }
      }
    }
  '';
in {
  config = lib.mkIf isNiri {
    emily.eww.bins = [playerListener];
    xdg.configFile."eww/widgets/player.yuck".text = yuck;
    emily.eww.scssParts = [scss];
  };
}
