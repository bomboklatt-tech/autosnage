{
  description = "autosnage - NixOS Raspberry Pi kiosk image with VM testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
    }:
    let
      cfg = import ./config.nix;

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor = system: import nixpkgs { inherit system; };

      # Map a darwin system to its linux counterpart for build/host platform.
      # Per the nixcademy cross-compile article: we evaluate on darwin but
      # need a Linux platform string for builds.
      toLinux = builtins.replaceStrings [ "darwin" ] [ "linux" ];

      # Same-arch linux system for "what arch is the VM targeting?".
      linuxSysOf =
        system:
        let
          arch = nixpkgs.lib.elemAt (nixpkgs.lib.splitString "-" system) 0;
        in
        "${arch}-linux";

      overlay = (
        final: prev:
        prev.lib.packagesFromDirectoryRecursive {
          inherit (prev) callPackage;
          directory = ./pkgs;
        }
      );

      commonModules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./modules
      ];

      piExtra = [
        nixos-hardware.nixosModules."raspberry-pi-${cfg.pi.model}"
        ./modules/pi.nix
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ];

      # qemu-vm.nix is auto-applied via build-vm.nix's `virtualisation.vmVariant`
      # extendModules path (see nixos/modules/virtualisation/build-vm.nix). The
      # generated `system.build.vm` is a runner script that direct-boots the
      # guest kernel + initrd (no in-build install VM, no nested qemu). The
      # script itself is built on the user's host platform via host.pkgs, so
      # qemu runs natively on darwin (HVF) instead of TCG-on-aarch64-on-aarch64.
      vmExtra = hostSystem: [
        (
          _: {
            kiosk.vmMode = true;
            virtualisation.vmVariant = {
              virtualisation = {
                host.pkgs = nixpkgs.legacyPackages.${hostSystem};
                cores = cfg.vm.cores;
                memorySize = cfg.vm.memorySize;
                diskSize = cfg.vm.diskSize;
                graphics = true;
              };
            };
          }
        )
      ];

      # Cross-compile-aware constructor. hostPlatform = where the image runs;
      # buildPlatform = where the build happens. When they differ, nix uses
      # cross-compile. When they match, it's a native build (potentially via
      # a remote builder like nix.linux-builder on darwin).
      mkSystem =
        extraModules: hostPlatform: buildPlatform:
        nixpkgs.lib.nixosSystem {
          modules = commonModules ++ extraModules ++ [
            { nixpkgs = { inherit hostPlatform buildPlatform; }; }
          ];
          specialArgs = { inherit cfg; };
        };
    in
    {
      # Canonical config = the Pi. Built outputs go through `packages`.
      nixosConfigurations.autosnage = mkSystem piExtra cfg.pi.system cfg.pi.system;

      packages = forAllSystems (system: {
        sd-image =
          (mkSystem piExtra "aarch64-linux" (toLinux system)).config.system.build.sdImage;
        vm =
          (mkSystem (vmExtra system) (linuxSysOf system) (toLinux system)).config.system.build.vm;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nh
              pkgs.nix-output-monitor
              pkgs.qemu
              pkgs.nixfmt-rfc-style
              pkgs.nil
              pkgs.statix
              pkgs.deadnix
              pkgs.findutils
            ];
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.writeShellApplication {
          name = "autosnage-fmt";
          runtimeInputs = [
            pkgs.nixfmt-rfc-style
            pkgs.findutils
          ];
          text = ''
            find . -name '*.nix' -not -path './result*' -print0 | xargs -0 nixfmt
          '';
        }
      );
    };
}
