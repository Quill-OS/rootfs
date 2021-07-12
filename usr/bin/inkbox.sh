#!/bin/sh

FIRST_LAUNCH_SINCE_BOOT=`cat /tmp/boot 2>/dev/null`
ROOTED=`cat /opt/root/rooted`
DEVICE=`cat /opt/inkbox_device`

if [ "$FIRST_LAUNCH_SINCE_BOOT" == "true" ]; then
	echo "false" > /tmp/boot
	echo "true" > /kobo/tmp/first_launch_since_boot
else
	echo "false" > /kobo/tmp/first_launch_since_boot
fi

echo 0 > /sys/class/graphics/fb0/rotate
chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh &
if [ "$DEVICE" == "n705" ] || [ "$DEVICE" == "n905b" ] || [ "$DEVICE" == "n905c" ] || [ "$DEVICE" == "n613" ]; then
	echo 0 > /sys/class/leds/pmic_ledsb/brightness
elif [ "$DEVICE" == "n873" ]; then
	echo 1 > /sys/class/leds/GLED/brightness ; echo 0 > /sys/class/leds/GLED/brightness
else
	echo 0 > /sys/class/leds/pmic_ledsb/brightness
fi

if [ "$ROOTED" == "true" ]; then
	rc-service sshd start &
else
	echo "Not starting SSHd, device is not rooted."
fi
