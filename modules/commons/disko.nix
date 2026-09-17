{inputs, ...}: let
  mountOptions = ["compress=zstd" "noatime"];
in {
  flake.modules.nixos.disko = {
    imports = [inputs.disko.nixosModules.disko];

    disko.devices.disk.main = {
      type = "disk";
      content.type = "gpt";

      content.partitions.esp = {
        name = "ESP";
        type = "EF00";
        size = "1G";

        content.type = "filesystem";
        content.format = "vfat";
        content.mountpoint = "/boot";
        content.mountOptions = ["umask=0077"];
      };

      content.partitions.root = {
        name = "root";
        size = "100%";

        content.type = "luks";
        content.name = "cryptroot";
        content.settings.allowDiscards = true;
        content.settings.crypttabExtraOpts = ["tpm2-device=auto"];

        content.content.type = "btrfs";
        content.content.extraArgs = ["-f"];

        content.content.subvolumes."/root" = {
          inherit mountOptions;
          mountpoint = "/";
        };
        content.content.subvolumes."/home" = {
          inherit mountOptions;
          mountpoint = "/home";
        };
        content.content.subvolumes."/nix" = {
          inherit mountOptions;
          mountpoint = "/nix";
        };
        content.content.subvolumes."/persistent" = {
          inherit mountOptions;
          mountpoint = "/persistent";
        };
        content.content.subvolumes."/swap" = {
          mountpoint = "/swap";
          mountOptions = ["noatime"];
          swap.swapfile.size = "8G";
        };
      };
    };

    services.btrfs.autoScrub.enable = true;
    services.btrfs.autoScrub.fileSystems = ["/"];
  };
}
