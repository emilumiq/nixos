{
  pkgs,
  ...
}: let
  btfix = pkgs.runCommand "set-nvram-btfix" {} ''
    mkdir -p $out/bin
    cp ${../../assets/btfix/set-nvram-btfix} $out/bin/set-nvram-btfix
    chmod 0755 $out/bin/set-nvram-btfix
  '';
in {
  launchd.daemons.btfix = {
    script = ''
      i=0
      while [ "$i" -lt 20 ]; do
        ${btfix}/bin/set-nvram-btfix || true
        sleep 3
        i=$((i + 1))
      done
      killall -9 bluetoothd 2>/dev/null || true
      sleep 5
      ${btfix}/bin/set-nvram-btfix || true
    '';
    serviceConfig = {
      Label = "com.emily.btfix";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/btfix.log";
      StandardErrorPath = "/var/log/btfix.log";
      ThrottleInterval = 30;
    };
  };
}
