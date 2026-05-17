{ writeShellApplication, systemd, sudo }:

writeShellApplication {
  name = "vm-smoke";
  runtimeInputs = [ systemd sudo ];
  text = ''
    cat <<'MSG'

    ============================================================
              autosnage vm-smoke: kiosk pipeline OK
    ============================================================

    MSG
    sleep 3
    sudo systemctl poweroff
    # Block until shutdown actually kills us so xinitrc doesn't loop
    # during the shutdown window.
    sleep infinity
  '';
}
