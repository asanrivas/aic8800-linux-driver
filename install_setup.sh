#!/bin/bash

echo "##################################################"
echo "AIC Wi-Fi driver Setup Files script"
echo "2023.03.09 v1.1.0"
echo "##################################################"

Main_version=`uname -r |awk -F'.' '{print $1}'`
Minor_version=`uname -r |awk -F'.' '{print $2}'`

echo "Authentication requested [root] for setup:"
if [ "`uname -r |grep fc`" == " " ]; then
	sudo su -c "cp -rf ./fw/aic8800D80 /lib/firmware/"; Error=$?
	sudo su -c "cp ./tools/aic.rules /etc/udev/rules.d"; Error=$?
    sudo su -c "udevadm trigger"; Error=$?
	sudo su -c "udevadm control --reload"; Error=$?
	if [ -L /dev/aicudisk ]; then
		sudo su -c "eject /dev/aicudisk"; Error=$?
	fi
	# Configure auto-load on boot
	sudo su -c "echo '# AIC8800 WiFi driver modules - auto-load on boot' > /etc/modules-load.d/aic8800.conf"; Error=$?
	sudo su -c "echo 'aic_load_fw' >> /etc/modules-load.d/aic8800.conf"; Error=$?
	sudo su -c "echo 'aic8800_fdrv' >> /etc/modules-load.d/aic8800.conf"; Error=$?
	sudo su -c "depmod -a"; Error=$?
else
	su -c "cp -rf ./fw/aic8800D80 /lib/firmware/"; Error=$?
	su -c "cp ./tools/aic.rules /etc/udev/rules.d"; Error=$?
    su -c "udevadm trigger"; Error=$?
	su -c "udevadm control --reload"; Error=$?
	if [ -L /dev/aicudisk ]; then
		su -c "eject /dev/aicudisk"; Error=$?
	fi
	# Configure auto-load on boot
	su -c "echo '# AIC8800 WiFi driver modules - auto-load on boot' > /etc/modules-load.d/aic8800.conf"; Error=$?
	su -c "echo 'aic_load_fw' >> /etc/modules-load.d/aic8800.conf"; Error=$?
	su -c "echo 'aic8800_fdrv' >> /etc/modules-load.d/aic8800.conf"; Error=$?
	su -c "depmod -a"; Error=$?
fi

echo "##################################################"
echo "The Setup Script is completed !"
echo "Modules will auto-load on next boot."
echo "##################################################"
