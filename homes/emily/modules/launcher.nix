{pkgs, ...}: {
  home.packages = with pkgs; [vicinae];
  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher server";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
