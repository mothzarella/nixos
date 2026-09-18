{
  config,
  pkgs,
  lib,
  ...
}: let
  normal = config.users.users |> lib.filterAttrs (_: u: u.isNormalUser);
in {
  programs.xwayland.enable = true;
  programs.dconf.enable = true;

  security.soteria.enable = true; # polkit agent
  security.rtkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = "${lib.getExe pkgs.tuigreet} --remember --remember-user-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  };
  security.pam.services.greetd.enableGnomeKeyring = true; # unlock keyring with the login password
  programs.gtklock.enable = true; # registers its pam service too

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [inter nerd-fonts.jetbrains-mono noto-fonts-color-emoji];
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["Inter"];
    monospace = ["JetBrainsMono Nerd Font"];
    emoji = ["Noto Color Emoji"];
  };

  services.fwupd.enable = true;
  services.udisks2.enable = true;
  services.udev.packages = [pkgs.brightnessctl];
  users.groups.video.members = builtins.attrNames normal; # brightnessctl udev rule

  services.journald.settings.Journal.SystemMaxUse = "200M"; # /var/log is persisted

  # ------------------------------------------------------------------------ xdg
  nix.settings.use-xdg-base-directories = true;
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [xdg-ninja xdg-user-dirs mako wl-clipboard grim slurp swayidle brightnessctl bluetui udiskie adwaita-icon-theme];
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # electron/chromium on native wayland
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  environment.etc."xdg/user-dirs.defaults".text = ''
    DESKTOP=Desktop
    DOCUMENTS=Documents
    DOWNLOAD=Downloads
    PICTURES=Pictures
    PROJECTS=Projects
  '';

  # ----------------------------------------------------------------- persistent
  preservation.preserveAt."/persistent".directories = [
    "/var/lib/systemd/backlight"
    "/var/lib/bluetooth" # pairings
    {
      directory = "/var/cache/tuigreet"; # --remember
      user = "greeter";
      group = "greeter";
    }
  ];

  preservation.preserveAt."/persistent".users =
    lib.mapAttrs (_: _: {
      directories = [
        ".local/share/keyrings" # gnome-keyring
        ".config/dconf"
        "Desktop"
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
      ];
    })
    normal;
}
