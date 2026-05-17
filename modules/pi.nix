{ lib, cfg, ... }:

{
  sdImage.compressImage = false;

  hardware.raspberry-pi.configtxt.settings.all = lib.mkMerge [
    (lib.mkIf (cfg.display.primary == "av") {
      enable_tvout = true;
      sdtv_mode = 2;
      sdtv_aspect = 3;
    })
    (lib.mkIf (cfg.display.primary == "hdmi" || cfg.display.fallback == "hdmi") {
      hdmi_force_hotplug = true;
      hdmi_group = 1;
      hdmi_mode = 16;
    })
  ];

  # Workaround for the Pi 5 sd-image build: some kernel modules listed by
  # nixos-hardware aren't present in the Pi rpt1 kernel. Tell initrd to skip
  # the missing ones and explicitly opt out the offenders so the build stops
  # demanding them.
  #   https://github.com/NixOS/nixpkgs/issues/154163
  #   https://github.com/NixOS/nixpkgs/issues/109280
  #   https://discourse.nixos.org/t/cannot-build-raspberry-pi-sdimage-module-dw-hdmi-not-found/71804
  boot.initrd.allowMissingModules = lib.mkForce true;
  boot.initrd.availableKernelModules = {
    dw-hdmi = lib.mkForce false;
    dw-mipi-dsi = lib.mkForce false;
    rockchipdrm = lib.mkForce false;
    rockchip-rga = lib.mkForce false;
    phy-rockchip-pcie = lib.mkForce false;
    pcie-rockchip-host = lib.mkForce false;
    pwm-sun4i = lib.mkForce false;
    sun4i-drm = lib.mkForce false;
    sun8i-mixer = lib.mkForce false;
  };
}
