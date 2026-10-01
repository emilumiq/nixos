{pkgs, ...}: let
  btReset = pkgs.writeShellScript "bt-reset" ''
    set -eu
    for dev in /sys/bus/usb/devices/*; do
      if [ -f "$dev/idVendor" ] && [ -f "$dev/idProduct" ] && [ -f "$dev/authorized" ]; then
        v=$(cat "$dev/idVendor"); p=$(cat "$dev/idProduct")
        if { [ "$v" = "2357" ]; } || { [ "$v" = "0bda" ] && { [ "$p" = "8771" ] || [ "$p" = "8761" ]; }; }; then
          echo 0 > "$dev/authorized" || true
          sleep 1
          echo 1 > "$dev/authorized" || true
        fi
      fi
    done
    sleep 2
    if [ ! -e /sys/class/bluetooth/hci0 ]; then
      ${pkgs.kmod}/bin/modprobe -r btusb btrtl btintel btbcm btmtk 2>/dev/null || true
      sleep 1
      ${pkgs.kmod}/bin/modprobe btusb reset=1 || true
      sleep 3
    fi
    ${pkgs.bluez}/bin/hciconfig hci0 up 2>/dev/null || true
  '';
in {
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "btusb.enable_autosuspend=0"
  ];
  boot.extraModprobeConfig = ''
    options btusb reset=1
  '';
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        EnableIsoSocket = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2357", ATTR{power/autosuspend}="-1"
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="bluetooth", KERNEL=="hci*", RUN+="${pkgs.bluez}/bin/hciconfig %k up"
  '';
  systemd.services.bluetooth.serviceConfig.ExecStartPre = ["${btReset}"];
}
