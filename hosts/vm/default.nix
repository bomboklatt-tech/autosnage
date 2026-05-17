{
  config,
  lib,
  nixpkgs,
  userSystem,
  ...
}:

let
  # The VM target arch follows the user's host arch (we run qemu natively on
  # whatever they're using). aarch64-darwin -> aarch64-linux guest, etc.
  arch = lib.elemAt (lib.splitString "-" userSystem) 0;
in
{
  nixpkgs.hostPlatform = "${arch}-linux";

  kiosk.vmMode = true;

  # qemu-vm.nix is auto-applied via build-vm.nix's `virtualisation.vmVariant`
  # extendModules path. The generated `system.build.vm` is a runner script
  # that direct-boots kernel + initrd (no install VM, no nested qemu). The
  # wrapper is built on the user's darwin/linux platform via host.pkgs, so
  # qemu runs natively (HVF / KVM) instead of TCG.
  virtualisation.vmVariant = {
    virtualisation = {
      host.pkgs = nixpkgs.legacyPackages.${userSystem};
      cores = 2;
      memorySize = 2048;
      diskSize = 8192;
      graphics = true;
    };
  };

  system.build.target = config.system.build.vm;
}
