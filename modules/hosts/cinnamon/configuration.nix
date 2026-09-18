# Dell G15 5530: i7-13650HX, Intel UHD (8086:a78b) + RTX 4060 Laptop (10de:28e0)
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.cinnamon = {
    config,
    pkgs,
    ...
  }: {
    imports = with nixos; [disko gaming networking preservation rollback secureboot silent tar];

    time.timeZone = "Europe/Rome";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";

    # ----------------------------------------------------------------- hardware
    disko.devices.disk.main.device = "/dev/disk/by-id/nvme-BC901_NVMe_SK_hynix_512GB__4YC6T000310706R22";
    hardware.facter.detected.boot.graphics.kernelModules = ["i915"];

    hardware.graphics.extraPackages = [pkgs.intel-media-driver];
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # driver Gen8+

    services.xserver.videoDrivers = ["modesetting" "nvidia"];
    hardware.nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.cachyos;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      dynamicBoost.enable = true;
      prime.offload.enable = true;
      prime.offload.enableOffloadCmd = true;
      prime.intelBusId = "PCI:0@0:2:0";
      prime.nvidiaBusId = "PCI:1@0:0:0";
    };

    services.thermald.enable = true;
    services.power-profiles-daemon.enable = true;
    preservation.preserveAt."/persistent".directories = ["/var/lib/power-profiles-daemon"];

    system.stateVersion = "26.11";
  };
}
