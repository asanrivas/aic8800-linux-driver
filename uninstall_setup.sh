#!/bin/bash
################################################################################
#			clean files
################################################################################
echo "Clean aic8800 wifi driver setup files!"
echo "Authentication requested [root] for clean:"
if [ "`uname -r |grep fc`" == " " ]; then
	  sudo su -c "rm -rf /lib/firmware/aic8800D80/"; Error=$?
	  sudo su -c "rm -f /etc/udev/rules.d/aic.rules"; Error=$?
	  sudo su -c "rm -f /etc/modules-load.d/aic8800.conf"; Error=$?
	  sudo su -c "udevadm control --reload"; Error=$?
	  sudo su -c "depmod -a"; Error=$?
else
	  su -c "rm -rf /lib/firmware/aic8800D80/"; Error=$?
	  su -c "rm -f /etc/udev/rules.d/aic.rules"; Error=$?
	  su -c "rm -f /etc/modules-load.d/aic8800.conf"; Error=$?
	  su -c "udevadm control --reload"; Error=$?
	  su -c "depmod -a"; Error=$?
fi

echo "The Uninstall Setup Script is completed!"
