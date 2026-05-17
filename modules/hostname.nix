{ cfg, lib, ... }:

{
  # Leave /etc/hostname unmanaged so our service can write to it.
  networking.hostName = lib.mkForce "";

  systemd.services.autosnage-hostname = {
    description = "Derive and apply MAC-suffix hostname on first boot";
    wantedBy = [ "multi-user.target" ];
    # Network interfaces are created by kernel + udev. Wait for udev to
    # finish processing the initial coldplug so /sys/class/net is populated.
    after = [
      "local-fs.target"
      "systemd-udev-trigger.service"
    ];
    # Must run before anything that reads the hostname: hostnamed, the
    # network stack, and getty (login captures $HOSTNAME at exec time).
    before = [
      "network-pre.target"
      "systemd-hostnamed.service"
      "systemd-user-sessions.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      state=/var/lib/autosnage/hostname
      mkdir -p "$(dirname "$state")"
      if [ ! -s "$state" ]; then
        iface=$(ls /sys/class/net 2>/dev/null | grep -vw lo | head -n1 || true)
        if [ -n "''${iface:-}" ] && [ -f "/sys/class/net/$iface/address" ]; then
          mac=$(tr -d ':\n' < "/sys/class/net/$iface/address")
          suffix=$(printf '%s' "$mac" | tail -c6)
          echo "${cfg.hostnameBase}-$suffix" > "$state"
        else
          echo "${cfg.hostnameBase}" > "$state"
        fi
      fi
      name=$(cat "$state")
      # /etc/hostname is unmanaged (mkForce ""), so we write directly.
      echo "$name" > /etc/hostname
      echo "$name" > /proc/sys/kernel/hostname
    '';
  };
}
