{
  config,
  inputs,
  ...
}: {
  flake.modules.nixos.iso = {
    config,
    lib,
    modulesPath,
    pkgs,
    ...
  }: let
    install = pkgs.writeShellApplication {
      name = "install";
      runtimeInputs = with pkgs; [disko mkpasswd nixos-install-tools];
      text = ''
        host=''${1:?usage: install <host>   (FLAKE=<ref> to override the embedded flake)}
        flake=''${FLAKE:-${inputs.self}}

        disko --mode destroy,format,mount --yes-wipe-all-disks --flake "$flake#$host"

        install -d -m 700 /mnt/persistent/passwords
        echo "password for tar:"
        mkpasswd -m yescrypt > /mnt/persistent/passwords/tar
        chmod 600 /mnt/persistent/passwords/tar

        mkdir -p /mnt/tmp
        TMPDIR=/mnt/tmp nixos-install --flake "$flake#$host" --no-root-passwd --no-channel-copy
      '';
    };

    name = "${config.networking.hostName}-${config.system.nixos.release}-${inputs.self.shortRev or "dirty"}-${pkgs.stdenv.hostPlatform.uname.processor}";
  in {
    imports = [
      "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      inputs.chaotic.nixosModules.nyx-cache # cache cachyos kernel
    ];

    image.baseName = lib.mkImageMediaOverride name;
    isoImage = {
      volumeID = lib.mkImageMediaOverride name;
      appendToMenuLabel = "";
      edition = "";
      squashfsCompression = "zstd -Xcompression-level 6";
    };

    systemd.services.sshd.wantedBy = lib.mkForce ["multi-user.target"];
    users.users.root.password = "nixos"; # ssh root@<ip>
    users.users.root.initialHashedPassword = lib.mkForce null;

    system.switch.enable = false; # immutable
    boot.supportedFilesystems.zfs = false;
    boot.swraid.enable = lib.mkForce false;
    nixpkgs.overlays = lib.mkForce []; # pkgs are readOnly

    system.installer.channel.enable = false; # no nixpkgs copy
    nix.settings = {
      log-lines = 50;
      warn-dirty = false;
      http-connections = 50;
      connect-timeout = 5;
    };

    documentation.enable = lib.mkForce false;
    environment.defaultPackages = lib.mkForce [];

    environment.systemPackages = [install pkgs.nixos-facter];

    # ------------------------------------------------------------------ memory
    zramSwap.enable = true;
    boot.kernelParams = ["zswap.enabled=1" "zswap.max_pool_percent=50" "zswap.compressor=zstd" "zswap.zpool=zsmalloc"];
    boot.initrd.systemd.emergencyAccess = true;

    # ----------------------------------------------------------------- network
    networking.networkmanager.enable = true;
    networking.wireless.enable = lib.mkForce false;
  };

  perSystem.packages.iso = config.flake.nixosConfigurations.iso.config.system.build.isoImage;
}
