{
  config,
  pkgs,
  ...
}: {
  # Define a user account
  users.users.dan = {
    isNormalUser = true;
    description = "Dan";
    extraGroups = ["networkmanager" "wheel" "sudo"];
    shell = pkgs.zsh;

    # SSH key for remote access (you'll need to add your public key here)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ vm-minimal"
      # Add your SSH public key here for passwordless login
      # Example: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample dan@macbook"
    ];
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Basic shell environment
  environment.shells = with pkgs; [zsh];
  users.defaultUserShell = pkgs.zsh;

  # Enable Home Manager for the user
  # The actual Home Manager configuration will be in home/dan/nixos-vm-minimal.nix
}
