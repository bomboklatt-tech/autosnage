{
  pkgs,
  lib,
  ...
}:

{
  # ATF for RK3399 ships with vendor binary blobs (bsd3 + unfreeRedistributable),
  # so nixpkgs flags it unfree. Whitelist just that derivation, not a blanket
  # allowUnfree. Other unfree packages still trip the gate.
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "arm-trusted-firmware-rk3399" ];

  # The board's u-boot lives on the SD card itself, not the SPI chip. Layout:
  #   sector 64    (32 KiB)  idbloader.img  (RK3399 bootrom hands off here)
  #   sector 16384 (8 MiB)   u-boot.itb     (proper u-boot + ATF + dtb)
  # The default firmwarePartitionOffset of 8 MiB collides with u-boot.itb, so
  # we push it to 16 MiB to leave room.
  sdImage.firmwarePartitionOffset = 16;
  sdImage.postBuildCommands = ''
    dd if=${pkgs.ubootRockPro64}/idbloader.img of=$img bs=512 seek=64    conv=notrunc,fsync
    dd if=${pkgs.ubootRockPro64}/u-boot.itb    of=$img bs=512 seek=16384 conv=notrunc,fsync
  '';

  # Kiosk's program renders on HDMI; nixos-hardware defaults this option to
  # "hdmi" already, this just makes the choice explicit.
  hardware.rockpro64.console = "hdmi";

  # The RK3399's GMAC driver mishandles checksum offload on large packets,
  # making TCP flaky. Disable on link-up. Wiki erratum.
  systemd.services.ethtool-rk3399-fix = {
    description = "Disable hw checksum offload on RK3399 GMAC";
    wantedBy = [ "network.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K eth0 rx off tx off";
      RemainAfterExit = true;
    };
  };

  # extlinux works once u-boot is in place. Same approach the Pi5 host uses,
  # the rockpro64 nixos-hardware module doesn't set a loader itself.
  boot.loader.grub.enable = lib.mkDefault false;
  boot.loader.generic-extlinux-compatible.enable = lib.mkDefault true;
}
