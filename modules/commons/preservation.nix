{inputs, ...}: {
  flake.modules.nixos.preservation = {
    imports = [inputs.preservation.nixosModules.preservation];

    fileSystems."/persistent".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persistent".directories = [
        "/var/lib/systemd/timers"
        "/var/log"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
      ];
      preserveAt."/persistent".files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        {
          file = "/var/lib/systemd/random-seed";
          how = "symlink";
          inInitrd = true;
          configureParent = true;
        }
      ];
    };

    systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
  };
}
