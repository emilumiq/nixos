{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  isNiri = osConfig.desktop.environment == "niri";

  python = pkgs.python3.withPackages (ps: [ps.dbus-next]);

  notifListener = pkgs.writeScriptBin "notif-listener" ''
    #!${python}/bin/python3
    import asyncio, json, os, re, subprocess
    from collections import OrderedDict
    from dbus_next.aio import MessageBus
    from dbus_next.service import ServiceInterface, method
    from dbus_next import BusType

    APP_ICONS = {
        "firefox": "󰈹", "chromium": "󰈹", "google-chrome": "󰈹", "helium": "󰈹",
        "telegram": "", "discord": "󰙯", "spotify": "",
        "mpv": "󰐊", "vlc": "󰕼", "thunderbird": "󰇮",
        "code": "󰨞", "bash": "", "zsh": "", "default": "󰂚"
    }
    TIMEOUT_DEFAULT = 5
    MAX_NOTIFS      = 3
    MAX_HISTORY     = 3
    notifications   = OrderedDict()
    history         = []
    next_id         = 1

    def get_icon(app):
        return APP_ICONS.get((app or "").lower().split()[0], APP_ICONS["default"])

    def eww_update(data):
        arr  = json.dumps(list(data.values()), ensure_ascii=False)
        hist = json.dumps(history, ensure_ascii=False)
        cnt  = str(len(data))
        subprocess.Popen(
            ["eww", "update",
             f"notifications={arr}",
             f"notif-count={cnt}",
             f"notif-history={hist}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )

    def remove_notif(nid):
        if nid in notifications:
            del notifications[nid]
            eww_update(notifications)

    class Notifs(ServiceInterface):
        def __init__(self, loop):
            super().__init__("org.freedesktop.Notifications")
            self._loop = loop

        @method()
        def GetCapabilities(self) -> "as":
            return ["body", "body-markup", "icon-static"]

        @method()
        def GetServerInformation(self) -> "ssss":
            return ["eww-notif", "eww", "1.0", "1.2"]

        @method()
        def Notify(self, app_name:"s", replaces_id:"u", app_icon:"s",
                   summary:"s", body:"s", actions:"as",
                   hints:"a{sv}", expire_timeout:"i") -> "u":
            global next_id
            nid = replaces_id if replaces_id != 0 else next_id
            if replaces_id == 0:
                next_id += 1

            clean_body = re.sub(r"<[^>]+>", "", body).strip()

            img_path = ""

            notifications[nid] = {
                "id": nid,
                "app": app_name or "notify",
                "summary": summary,
                "body": clean_body,
                "icon": get_icon(app_name),
                "image": img_path
            }

            while len(notifications) > MAX_NOTIFS:
                notifications.popitem(last=False)

            entry = {
                "id": nid,
                "app": app_name or "notify",
                "summary": summary,
                "body": clean_body,
                "icon": get_icon(app_name),
                "image": img_path
            }
            for i, h in enumerate(history):
                if h["id"] == nid:
                    history[i] = entry
                    break
            else:
                history.append(entry)
            if len(history) > MAX_HISTORY:
                history.pop(0)

            eww_update(notifications)

            secs = expire_timeout / 1000 if expire_timeout > 0 else TIMEOUT_DEFAULT
            self._loop.call_later(secs, lambda: remove_notif(nid))
            return nid

        @method()
        def CloseNotification(self, id:"u"):
            remove_notif(id)

    async def main():
        loop = asyncio.get_event_loop()
        bus  = await MessageBus(bus_type=BusType.SESSION).connect()
        bus.export("/org/freedesktop/Notifications", Notifs(loop))
        await bus.request_name("org.freedesktop.Notifications")
        eww_update(notifications)
        await loop.create_future()

    if __name__ == "__main__":
        asyncio.run(main())
  '';

  yuck = ''
    (defvar notifications '[]')
    (defvar notif-count 0)
    (defvar notif-history '[]')

    (defwidget notif-item [summary body app icon image]
      (box :class "notif_item" :orientation "h" :space-evenly false :spacing 12
        (box :class "notif_img"
             :style {image != "" ? "background-image: url('noimage-unused');" : ""}
             :visible {image != ""}
             :width 50 :height 50)
        (box :class "notif_icon_wrap" :valign "start" :visible {image == ""}
          (label :class "notif_icon" :text {icon != "" ? icon : "•"}))
        (box :orientation "v" :space-evenly false :valign "center" :hexpand true
          (label :class "notif_app"     :text app     :halign "start" :limit-width 40)
          (label :class "notif_summary" :text summary :halign "start" :limit-width 40)
          (label :class "notif_body"    :text body    :halign "start" :limit-width 40
                 :visible {body != ""}))))

    (defwidget notif-window []
      (box :orientation "v" :space-evenly false :spacing 6 :valign "start"
        (for n in notifications
          (notif-item
            :summary {n.summary}
            :body    {n.body}
            :app     {n.app}
            :icon    {n.icon}
            :image   {n.image}))))
  '';

  scss = ''
    .notif_item {
      background-color: $bg;
      border-radius: 6px;
      padding: 10px 12px;
      min-width: 320px;

      .notif_icon_wrap {
        min-width: 28px;

        .notif_icon {
          font-size: 1.2rem;
          color: $accent;
        }
      }

      .notif_img {
        border-radius: 4px;
        background-size: cover;
        background-position: center;
        background-repeat: no-repeat;
        background-color: $bg-alt;
      }

      .notif_app {
        font-size: 0.75rem;
        color: $accent;
        font-weight: bold;
      }

      .notif_summary {
        font-size: 0.95rem;
        font-weight: bold;
        color: $fg;
      }

      .notif_body {
        font-size: 0.85rem;
        color: $fg-alt;
      }
    }
  '';
in {
  config = lib.mkIf isNiri {
    emily.eww.bins = [notifListener];
    xdg.configFile."eww/widgets/notifs.yuck".text = yuck;
    emily.eww.scssParts = [scss];

    systemd.user.services.eww-notif = {
      Unit = {
        Description = "eww notification daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Environment = "PATH=${lib.makeBinPath [pkgs.eww notifListener]}";
        ExecStart = "${notifListener}/bin/notif-listener";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
