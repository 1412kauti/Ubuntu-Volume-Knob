sudo cp 99-usb-knob.hwdb /etc/udev/hwdb.d/
sudo cp 99-usb-knob.rules /etc/udev/rules.d/
sudo systemd-hwdb update
sudo udevadm trigger