{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  isNiri = osConfig.desktop.environment == "niri";

  volQuery = pkgs.writeShellScriptBin "vol-query" ''
    out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || out="Volume: 0"
    level=$(echo "$out" | grep -o '[0-9]*\.[0-9]*' | head -n 1)
    [ -z "$level" ] && level=0
    muted=false
    echo "$out" | grep -q MUTED && muted=true
    pct=$(awk "BEGIN { v=$level*100; if (v>100) v=100; if (v<0) v=0; printf \"%d\", v }")
    desc=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -m1 "node.description" | sed 's/.*= "\(.*\)"/\1/')
    device=$(echo "$desc" | sed 's/Built-in Audio //; s/Digital Stereo //; s/ (.*//')
    echo "{\"percent\": \"$pct\", \"muted\": $muted, \"device\": \"$device\"}"
  '';

  volListener = pkgs.writeShellScriptBin "vol-listener" ''
    vol-query
    while sleep 1; do vol-query; done
  '';

  volPopup = pkgs.writeShellScriptBin "vol-popup" ''
    LOCK_FILE="/tmp/eww-volume-timer.lock"
    timeout 3 eww update volume="$(vol-query)"
    if ! timeout 3 eww active-windows | grep -q "volume"; then
      timeout 3 eww open volume >/dev/null 2>&1
    fi
    if [ -f "$LOCK_FILE" ]; then
      PID=$(cat "$LOCK_FILE")
      kill "$PID" >/dev/null 2>&1
      rm -f "$LOCK_FILE"
    fi
    (
      sleep 2
      timeout 3 eww close volume >/dev/null 2>&1
      rm -f "$LOCK_FILE"
    ) &
    echo $! > "$LOCK_FILE"
  '';

  yuck = ''
    (deflisten volume
      :initial '{"percent": "0", "muted": false, "device": ""}'
      "vol-listener")

    (defwidget volume-popup []
      (box :class "volume_pop" :hexpand true
        (box :class "scale"
          (scale
            :min 0 :max 101
            :value {volume.muted ? 0 : volume.percent}
            :active false))))
  '';

  scss = ''
    .volume_pop {
      background-color: $bg;
      border-radius: 6px;
      padding: 0.5px;

      label {
        font-size: 2rem;
        padding-right: 1.2rem;
        color: $fg;
      }

      scale {
        trough {
          all: unset;
          background-color: $bg-alt;
          border-radius: 6px;
          min-height: 40px;
          min-width: 200px;

          highlight {
            all: unset;
            background-color: $fg;
            border-radius: 6px;
          }
        }

        slider { all: unset; }
      }
    }
  '';
in {
  config = lib.mkIf isNiri {
    emily.eww.bins = [volQuery volListener volPopup];
    xdg.configFile."eww/widgets/volume.yuck".text = yuck;
    emily.eww.scssParts = [scss];
  };
}
