{
  flake.modules.nixos.networking = {
    networking.networkmanager.enable = true;
    systemd.services.NetworkManager-wait-online.enable = false;

    boot = {
      kernelModules = ["tcp_bbr"];
      kernel.sysctl = {
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "cake";
      };
    };

    preservation.preserveAt."/persistent".directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      "/var/lib/systemd/rfkill"
    ];
  };
}
