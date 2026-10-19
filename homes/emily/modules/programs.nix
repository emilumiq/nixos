{
  pkgs,
  inputs,
  ...
}: {
  home.packages =
    (with pkgs; [
      gnome-text-editor
      loupe
      celluloid
      steam-run
      telegram-desktop
    ])
    ++ [
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
