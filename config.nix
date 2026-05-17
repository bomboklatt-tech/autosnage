{
  username = "user";
  hostnameBase = "autosnage";

  pi = {
    system = "aarch64-linux";
    model = "5";
  };

  display = {
    primary = "av";
    fallback = "hdmi";
  };

  wifi = { };

  sshKeys = [ ];

  # kiosk.program = "vm-smoke";
  kiosk.program = "acidwarp";

  vm = {
    cores = 2;
    memorySize = 2048;
    diskSize = 8192;
  };
}
