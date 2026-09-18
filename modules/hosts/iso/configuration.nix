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
    nixinstall = pkgs.writeShellApplication {
      name = "nixinstall";
      runtimeInputs = [(pkgs.disko.override {nix = config.nix.package;}) config.nix.package pkgs.mkpasswd config.system.build.nixos-install]; # force disko to use lix
      text = ''
        host=''${1:?usage: nixinstall <host>   (FLAKE=<ref> to override the embedded flake)}
        flake=''${FLAKE:-${inputs.self}}

        disko --mode destroy,format,mount --yes-wipe-all-disks --flake "$flake#$host"

        install -d -m 700 /mnt/persistent/passwords
        read -ra users <<< "$(nix eval --raw "$flake#nixosConfigurations.$host.config.users.users" --apply 'us: toString (builtins.filter (n: (builtins.getAttr n us).isNormalUser) (builtins.attrNames us))')"
        for u in "''${users[@]}"; do
          echo "password for $u:"
          mkpasswd -m yescrypt > "/mnt/persistent/passwords/$u"
          chmod 600 "/mnt/persistent/passwords/$u"
        done

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

    security.pam.loginLimits = [
      {
        domain = "*";
        item = "nofile";
        type = "-";
        value = "65536";
      }
    ]; # "too many open files" on big installs

    nix.settings = {
      log-lines = 50;
      warn-dirty = false;
      http-connections = 50;
      connect-timeout = 5;
      flake-registry = ""; # flake is embedded
      accept-flake-config = false;
    };

    documentation.enable = lib.mkForce false;
    environment.defaultPackages = lib.mkForce [];

    system = {
      installer.channel.enable = false; # no nixpkgs copy
      extraDependencies = lib.mkForce [];
      etc.overlay.enable = true;
      disableInstallerTools = true;
      tools = {
        nixos-install.enable = true;
        nixos-enter.enable = true;
      };
    };
    services.userborn.enable = true; # drops perl

    environment.systemPackages = [nixinstall pkgs.nixos-facter];

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
