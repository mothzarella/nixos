{
  config,
  inputs,
  lib,
  ...
}: let
  users = builtins.readDir ./users |> builtins.attrNames |> map (lib.removeSuffix ".nix");
in {
  flake.modules.nixos =
    lib.genAttrs users (name: {
      imports = [config.flake.modules.nixos.user];
      users.users.${name} = {
        isNormalUser = true;
        hashedPasswordFile = "/persistent/passwords/${name}";
      };
      hjem.users.${name} = {};
    })
    // {
      user = {
        config,
        pkgs,
        ...
      }: {
        imports = [inputs.hjem.nixosModules.default];

        users.mutableUsers = false;
        hjem.extraModules = [{packages = with pkgs; [git ripgrep fd tree];}];

        preservation.preserveAt."/persistent".users =
          config.users.users
          |> lib.filterAttrs (_: u: u.isNormalUser)
          |> lib.mapAttrs (_: _: {
            directories = [
              {
                directory = ".ssh";
                mode = "0700";
              }
            ];
          });
      };
    };
}
