NOM := nix run nixpkgs\#nix-output-monitor --

.PHONY: help sd-image vm run-vm check fmt

help:
	@echo "Targets:"
	@echo "  sd-image  build the burnable Pi SD image (always aarch64-linux)"
	@echo "  vm        build the VM runner script (qemu-vm.nix direct-boot)"
	@echo "  run-vm    launch the VM via result/bin/run-*-vm (darwin: HVF; linux: KVM)"
	@echo "  check     nix flake check"
	@echo "  fmt       format all .nix files"

sd-image:
	$(NOM) build .#sd-image

vm:
	$(NOM) build .#vm

run-vm:
	./scripts/run-vm.sh

check:
	nix flake check

fmt:
	nix fmt
