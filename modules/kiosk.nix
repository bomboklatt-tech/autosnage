{
  lib,
  pkgs,
  cfg,
  ...
}:

let
  program = pkgs.${cfg.kiosk.program};
  # Run the kiosk program inside a fullscreen xterm so its stdout shows up
  # on the X display. Loop so the session restarts if the program exits.
  xinitrc = pkgs.writeShellScript "xinitrc" ''
    exec ${pkgs.xterm}/bin/xterm \
      -fullscreen \
      -fa Monospace -fs 14 \
      -bg black -fg white \
      -e ${pkgs.bash}/bin/bash -c \
      'while true; do ${program}/bin/${cfg.kiosk.program} || true; sleep 1; done'
  '';
in
{
  services.xserver.enable = true;
  services.xserver.videoDrivers = [
    "modesetting"
    "fbdev"
  ];
  services.xserver.displayManager.startx.enable = true;

  # hardware.graphics is disabled in modules/trim.nix; the modesetting and
  # fbdev drivers above don't strictly need GL. If GL is ever required, flip
  # `hardware.graphics.enable = lib.mkForce true;` here.

  services.getty.autologinUser = lib.mkDefault cfg.username;

  # startx checks ~/.xinitrc first - drop ours there at boot so we don't
  # need to pass a path. tmpfiles re-creates the symlink each boot, so it
  # survives store-path changes.
  systemd.tmpfiles.rules = [
    "L+ /home/${cfg.username}/.xinitrc - - - - ${xinitrc}"
  ];

  # Plain startx (not exec): if X exits or fails, fall through to a normal
  # shell on tty1 instead of looping via getty respawn.
  programs.bash.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
      startx
    fi
  '';
}
