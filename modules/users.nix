{ cfg, ... }:

{
  users.mutableUsers = false;

  # With hashedPassword = "!" and no root password, NixOS would normally
  # refuse the build to prevent lockout. On a kiosk the only login path is
  # tty1 autologin (which bypasses pam_unix) plus SSH keys if provided -
  # password login is intentionally impossible. Reflash to recover.
  users.allowNoPasswordLogin = true;

  users.users.${cfg.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "input"
    ];
    # Locked: no tty1 password login. getty autologin bypasses pam_unix
    # so the kiosk pipeline still works. SSH is key-only via ssh.nix.
    hashedPassword = "!";
    openssh.authorizedKeys.keys = cfg.sshKeys;
  };

  security.sudo.wheelNeedsPassword = false;
}
