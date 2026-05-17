{
  config,
  modulesPath,
  nixos-hardware,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-5
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ./hardware.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # Dispatch convention: the flake builds whatever each host exposes here.
  system.build.target = config.system.build.sdImage;
}
