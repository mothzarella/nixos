{inputs, ...}: {
  perSystem.nixpkgs.overlays = [
    (final: _:
      inputs.chaotic.utils.applyOverlay {
        pkgs = import inputs.chaotic.inputs.nixpkgs {
          inherit (final) config; # `allowUnfree` propagates
          inherit (final.stdenv.hostPlatform) system;
        };
      })
  ];

  flake.modules.nixos.gaming = {pkgs, ...}: {
    imports = [inputs.chaotic.nixosModules.default];
    chaotic.nyx.overlay.enable = false;

    boot.kernelPackages = pkgs.linuxPackages_cachyos;
  };
}
