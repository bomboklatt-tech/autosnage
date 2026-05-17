{
  lib,
  modulesPath,
  config,
  ...
}:

{
  imports = [
    # Modern perl-removal: systemd-initrd, overlayfs /etc, userborn (Rust).
    # Also asserts no perl in the closure.
    "${modulesPath}/profiles/perlless.nix"

    # Reflash-only kiosk -> no on-device nix, no switch-to-configuration.
    # Drops nix and its closure (~150-200 MB), sets users.mutableUsers=false
    # (already set), useNetworkd (compatible with our wpa_supplicant).
    "${modulesPath}/profiles/image-based-appliance.nix"
  ];

  # sd-image-aarch64.nix imports profiles/base.nix, which adds 25+ "rescue"
  # packages we never use: w3m (perl!), vim, testdisk, parted, gptfdisk,
  # cryptsetup, fuse, sshfs, tcpdump, screen, smartmontools, nvme-cli, etc.
  # Drop the whole profile - we have a fixed-hardware kiosk, not an installer.
  disabledModules = [
    "profiles/base.nix"
  ];

  # Removes nixos-rebuild + python. Composes with image-based-appliance's
  # nix.enable = false (which alone leaves the rebuild wrapper script behind).
  system.disableInstallerTools = true;

  # services.graphical-desktop is auto-enabled by services.xserver.enable. It
  # pulls xdg-utils (perl), nixos-icons, speechd, pipewire (with pulse+alsa),
  # the full xdg.* stack, and bumps fonts.enableDefaultPackages. Killing it
  # at the source is cleaner than disabling each downstream effect.
  # See <nixpkgs>/nixos/modules/services/misc/graphical-desktop.nix.
  services.graphical-desktop.enable = lib.mkForce false;

  # Defensive: even if another module turns these on later, force them off.
  services.speechd.enable = false;
  services.pipewire.enable = lib.mkForce false;
  hardware.bluetooth.enable = lib.mkForce false;

  # Drops cifs-utils -> samba.
  boot.supportedFilesystems = lib.mkForce {
    vfat = true;
    ext4 = true;
  };

  # Belt-and-braces: graphical-desktop already opts this out when disabled,
  # but be explicit so flipping it back on doesn't quietly re-pull fonts.
  fonts.enableDefaultPackages = false;

  # image-based-appliance imports profiles/minimal.nix which sets
  # xdg.icons.enable = mkDefault false. But the buildEnv setup hook for
  # icon caches runs `find $out/share/icons` unconditionally and fails when
  # the directory is missing. Re-enable to keep share/icons present.
  # Cost: hicolor-icon-theme, ~5 MB.
  xdg.icons.enable = true;

  # Drops the pinned nixpkgs flake source from /etc/nix/registry.json and the
  # legacy channel pointer. Mostly belt-and-braces now that image-based-appliance
  # sets nix.enable = false, but documents the intent.
  nix.registry = lib.mkForce { };
  nix.channel.enable = false;
  nix.nixPath = lib.mkForce [ ];

  # Catch regressions: fail the build if anything pulls these back in.
  # mkForce replaces perlless.nix's [ "perl" ] entirely so we can opt perl
  # back in for the VM (grub's installer needs it, and the VM can't use
  # systemd-boot without persistent EFI NVRAM - see flake.nix vmExtra).
  system.forbiddenDependenciesRegexes = lib.mkForce (
    [ "speech-dispatcher" ] ++ lib.optionals (!config.kiosk.vmMode) [ "perl" ]
  );
}
