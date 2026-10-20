{
  pkgs,
  ...
}: {
  home.username = "emily";
  home.homeDirectory = "/Users/emily";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.man.generateCaches = false;

  home.sessionPath = [
    "/Users/emily/.opencode/bin"
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_add_path /Users/emily/.opencode/bin
      set -g fish_greeting ""
      set -e SSH_ASKPASS
      set -e GIT_ASKPASS
      abbr -a dr 'nh darwin switch /Users/emily/dotfiles#hackintosh'
      abbr -a db 'nh darwin build /Users/emily/dotfiles#hackintosh'
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$nodejs$python$rust$golang$nix_shell$line_break$character";

      nix_shell = {
        symbol = "❄️ ";
        format = "via [$symbol$state]($style) ";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      credential.helper = "store";
      init.defaultBranch = "main";
      user.name = "emily";
      user.email = "emilumiq@gmail.com";
    };
  };

  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
  };
}
