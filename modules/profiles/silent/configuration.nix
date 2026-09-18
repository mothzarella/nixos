{
  flake.modules.nixos.silent = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [../.];

    programs.mango.enable = true;
    # started by mango.conf `exec-once`; nixpkgs module does not define it
    systemd.user.targets.mango-session = {
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target" "xdg-desktop-autostart.target"];
      after = ["graphical-session-pre.target"];
    };
    hjem.extraModules = [{files.".config/mango/config.conf".text = builtins.readFile ./mango.conf;}];

    environment.systemPackages = with pkgs; [foot fuzzel firefox];
    xdg.mime.defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
    preservation.preserveAt."/persistent".users =
      config.users.users
      |> lib.filterAttrs (_: u: u.isNormalUser)
      |> lib.mapAttrs (_: _: {directories = [".config/mozilla"];}); # firefox >= 147 is xdg
  };
}
