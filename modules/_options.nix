{
  lib,
  pkgs,
  cfg,
  ...
}:

{
  options.kiosk.vmMode = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      True when building the VM host, false for real hardware. Set by
      hosts/vm/default.nix; shared modules read it via config.kiosk.vmMode
      to skip wifi, etc.
    '';
  };

  # Eval-time sanity checks. These surface config.nix typos at `nix flake
  # check` time with a clear message, instead of failing deep in module eval.
  config.assertions = [
    {
      assertion = pkgs ? ${cfg.kiosk.program};
      message = ''
        config.nix sets kiosk.program = "${cfg.kiosk.program}" but
        pkgs.${cfg.kiosk.program} does not exist.
        Check that pkgs/${cfg.kiosk.program}/package.nix is present.
      '';
    }
    {
      assertion = builtins.elem cfg.display.primary [
        "av"
        "hdmi"
      ];
      message = ''
        config.nix sets display.primary = "${cfg.display.primary}",
        but only "av" or "hdmi" are supported.
      '';
    }
    {
      assertion = builtins.elem cfg.display.fallback [
        "av"
        "hdmi"
      ];
      message = ''
        config.nix sets display.fallback = "${cfg.display.fallback}",
        but only "av" or "hdmi" are supported.
      '';
    }
  ];
}
