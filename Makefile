NOM := nix run nixpkgs\#nix-output-monitor --

.PHONY: help rpi5 vm run-vm check fmt

help:
	@echo "Build targets (mirror packages.<system>.<name>):"
	@echo "  rpi5      build the Raspberry Pi 5 SD image"
	@echo "  vm        build the VM runner script (qemu-vm.nix direct-boot)"
	@echo "  run-vm    launch the VM via result/bin/run-*-vm (darwin: HVF; linux: KVM)"
	@echo "  check     nix flake check"
	@echo "  fmt       format all .nix files"

rpi5:
	$(NOM) build .#rpi5

vm:
	$(NOM) build .#vm

run-vm:
	./scripts/run-vm.sh

check:
	nix flake check

fmt:
	nix fmt
