switch:
	nh os switch .
	systemctl --user restart eww.service eww-windows.service eww-notif.service waybar.service || true

boot:
	nh os boot .

test:
	nh os test .

update:
	nix flake update

fmt:
	nix fmt .

check:
	nix flake check --show-trace
