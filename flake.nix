{
  description = "autosnage - NixOS kiosk image with VM testing";

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
      inherit (nixpkgs) lib;

      cfg = import ./config.nix;

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = lib.genAttrs systems;

      pkgsFor = system: import nixpkgs { inherit system; };

      # Map a darwin system to its linux counterpart. We evaluate on the user's
      # platform but builds (NixOS, sdImage, VM kernel) need a Linux platform
      # string. On darwin this resolves via nix.linux-builder.
      toLinux = builtins.replaceStrings [ "darwin" ] [ "linux" ];

      overlay = (
        final: prev:
        (prev.lib.packagesFromDirectoryRecursive {
          inherit (prev) callPackage;
          directory = ./pkgs;
        })
        // {
          # Massive closure win: SDL3 defaults pull libdecor (-> GTK4 ->
          # libadwaita -> zenity), wayland, pipewire, pulseaudio, vulkan,
          # ibus, jack, tray. Our kiosk uses X11 + KMSDRM only, no audio,
          # no Wayland. dosbox-staging links via sdl2-compat -> sdl3, so
          # this propagates through the full DOS chain.
          sdl3 = prev.sdl3.override {
            waylandSupport = false;
            libdecorSupport = false;
            pipewireSupport = false;
            pulseaudioSupport = false;
            ibusSupport = false;
            jackSupport = false;
            traySupport = false;
            dbusSupport = false;
          };
        }
      );

      commonModules = [
        { nixpkgs.overlays = [ overlay ]; }
        ./modules
      ];

      # Auto-discover hosts/. A host is any sub-directory; its default.nix
      # must set `system.build.target` to the artifact this flake should
      # build (sdImage for hardware hosts, vm for the VM host).
      hostNames = lib.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkHost =
        name: userSystem:
        lib.nixosSystem {
          modules = commonModules ++ [
            ./hosts/${name}
            { nixpkgs.buildPlatform = toLinux userSystem; }
          ];
          specialArgs = {
            inherit
              cfg
              nixpkgs
              nixos-hardware
              userSystem
              ;
          };
        };
    in
    {
      # Inspection-only entry points for hosts whose target platform is
      # fixed (i.e. real hardware). The VM is parametric on the user's
      # system and lives only under `packages.<system>.vm`.
      nixosConfigurations = {
        rpi5 = mkHost "rpi5" "aarch64-linux";
        rockpro64 = mkHost "rockpro64" "aarch64-linux";
      };

      packages = forAllSystems (
        system:
        lib.genAttrs hostNames (name: (mkHost name system).config.system.build.target)
      );

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
