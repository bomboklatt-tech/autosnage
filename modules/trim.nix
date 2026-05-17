{
  lib,
  ...
}:

{
  # ---- Documentation: nothing reads it on a kiosk, all of it is on the host.
  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    dev.enable = false;
  };

  # ---- Locales: one is enough, drops ~200 MB of glibc-locales.
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ];

  # ---- Default packages from <nixpkgs>/nixos/modules/config/system-path.nix:
  # rsync, strace, parted, perl etc. Kiosk doesn't ship a shell session.
  environment.defaultPackages = lib.mkForce [ ];

  # ---- Misc daemons & utilities that creep in via profiles.
  # nscd: superseded by userborn (perlless profile already brings userborn in).
  services.nscd.enable = lib.mkForce false;
  system.nssModules = lib.mkForce [ ];

  # libinput: X here doesn't take user input - the kiosk loops without keyboard.
  # If we ever need Ctrl+Alt+F2, the legacy keyboard driver in xkbcommon is enough.
  services.libinput.enable = lib.mkForce false;

  # command-not-found is a Perl script with a 60 MB SQLite database.
  programs.command-not-found.enable = false;

  # bash completion pulls bash-completion (~10 MB) - nothing tab-completes on a kiosk.
  programs.bash.completion.enable = false;

  # ---- Firmware: sd-image.nix enables hardware.enableAllHardware which pulls
  # the entire linux-firmware (~750 MB) regardless of the actual board. Each
  # host re-enables exactly what it needs in hosts/<name>/hardware.nix.
  hardware.enableAllHardware = lib.mkForce false;
  hardware.enableRedistributableFirmware = lib.mkForce false;

  # ---- Graphics: kiosk uses X with modesetting/fbdev; both fall back to
  # software rendering when hardware.graphics is off. Disabling drops the
  # entire mesa stack (~230 MB), llvm shader-compiler libs (~520 MB), and
  # python3 (~110 MB, pulled by mesa's runtime tooling).
  # If a future kiosk program needs GL, flip this back on (-> rebuilds mesa).
  hardware.graphics.enable = lib.mkForce false;
}
