{inputs, ...}: {
  flake.modules.nixos.user = {pkgs, ...}: {
    imports = [inputs.hjem.nixosModules.default];

    users.mutableUsers = false;
    users.users.tar = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = ["wheel"];
      hashedPasswordFile = "/persistent/passwords/tar";
    };

    hjem.users.tar.packages = with pkgs; [
      pfetch
      neovim
      git
      ripgrep
      fd
      fzf
      bat
      eza
      btop
      tree
      unzip
      wget
      curl
      jq
      claude-code
      codex
    ];
  };
}
