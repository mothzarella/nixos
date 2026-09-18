{
  config,
  inputs,
  lib,
  withSystem,
  ...
}: let
  inherit (config.flake.modules) nixos;

  hosts =
    lib.filesystem.listFilesRecursive ./.
    |> builtins.filter (lib.hasSuffix "facter.json") # single point of truth: `<host>/facter.json` = one host
    |> map (report: {
      inherit report;
      name = report |> dirOf |> baseNameOf;
      inherit ((lib.importJSON report)) system;
    });
in {
  imports =
    ./.
    |> lib.filesystem.listFilesRecursive
    |> builtins.filter (f: f != ./default.nix && lib.hasSuffix ".nix" (toString f));

  systems = hosts |> map (host: host.system) |> lib.unique;

  perSystem = {system, ...}: {
    imports = ["${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"];
    nixpkgs.hostPlatform = system;
    nixpkgs.config.allowUnfree = true;

    checks =
      hosts
      |> builtins.filter (host: host.system == system)
      |> map (host: lib.nameValuePair "configurations:nixos:${host.name}" config.flake.nixosConfigurations.${host.name}.config.system.build.toplevel)
      |> lib.listToAttrs;
  };

  flake.nixosConfigurations =
    hosts
    |> map (host:
      lib.nameValuePair host.name (withSystem host.system ({pkgs, ...}:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [
            inputs.nixpkgs.nixosModules.readOnlyPkgs
            nixos.${host.name}
            {
              networking.hostName = host.name;
              hardware.facter.reportPath = host.report;
              nixpkgs.pkgs = pkgs;

              nix.package = pkgs.lix;
              nix.channel.enable = false;
              nix.settings.trusted-users = ["@wheel"];
              nix.settings.experimental-features = ["nix-command" "flakes" "lix-custom-sub-commands" "pipe-operator"]; # nix calls it "pipe-operators" lol
              nix.settings.substituters = ["https://nix-community.cachix.org"];
              nix.settings.trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];

              nix.optimise.automatic = true;
              nix.gc = {
                automatic = true;
                dates = "weekly";
                options = "--delete-older-than 14d";
              };

              programs.nix-ld.enable = true;
            }
          ];
        })))
    |> lib.listToAttrs;
}
