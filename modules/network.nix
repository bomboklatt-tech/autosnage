{
  cfg,
  config,
  lib,
  ...
}:

let
  hasWifi = cfg.wifi != { } && !config.kiosk.vmMode;
in
{
  networking.useDHCP = lib.mkDefault true;

  networking.wireless = lib.mkIf hasWifi {
    enable = true;
    networks = lib.mapAttrs (_: psk: { inherit psk; }) cfg.wifi;
  };
}
