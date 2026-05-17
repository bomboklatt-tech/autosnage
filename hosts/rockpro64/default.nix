{
  config,
  modulesPath,
  nixos-hardware,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.pine64-rockpro64
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ./hardware.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  system.build.target = config.system.build.sdImage;
}
