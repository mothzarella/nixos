# Teclast F6: Celeron N3350 (Apollo Lake), Intel HD 500 (8086:5a85), QCA9377 WiFi/BT
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.kiwi = {pkgs, ...}: {
    imports = with nixos; [disko networking preservation rollback secureboot user];

    time.timeZone = "Europe/Rome";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";

    # ----------------------------------------------------------------- hardware
    disko.devices.disk.main.device = "/dev/disk/by-id/ata-Teclast_128GB_NA850-2280_AA000000000112608242";

    hardware.graphics.extraPackages = [pkgs.intel-media-driver];
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # driver Gen8+

    services.thermald.enable = true;
    services.tlp.enable = true; # no HWP on N3350

    system.stateVersion = "26.11";
  };
}
