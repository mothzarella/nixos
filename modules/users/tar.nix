{
  flake.modules.nixos.tar = {pkgs, ...}: {
    users.users.tar = {
      uid = 1000;
      extraGroups = ["wheel"];
    };

    hjem.users.tar.packages = with pkgs; [
      pfetch
      neovim
      fzf
      bat
      eza
      btop
      unzip
      wget
      curl
      jq
      claude-code
      codex
    ];

    preservation.preserveAt."/persistent".users.tar = {
      directories = [".claude" ".codex" ".config/nvim" ".local/share/nvim" ".local/state/nvim"];
      files = [".claude.json"];
    };
  };
}
