{ lib, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Master switch - cascades to all documentation.{man,nixos,dev,doc,info}.enable.
  documentation.enable = false;

  programs.command-not-found.enable = false;

  boot.tmp.cleanOnBoot = true;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
  ];

  services.udisks2.enable = false;

  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Drop the full glibc locale archive (~100 MB) - keep only what we use.
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "C.UTF-8/UTF-8"
  ];

  system.stateVersion = "25.11";
}
