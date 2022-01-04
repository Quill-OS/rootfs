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

if [ "$DEVICE" == "n705" ] || [ "$DEVICE" == "n905b" ] || [ "$DEVICE" == "n905c" ] || [ "$DEVICE" == "n613" ]; then
	FB_UR=3
	echo 0 > "/sys/class/leds/pmic_ledsb/brightness"
elif [ "$DEVICE" == "n873" ]; then
	FB_UR=0
	echo 1 > "/sys/class/leds/GLED/brightness" ; echo 0 > "/sys/class/leds/GLED/brightness"
elif [ "$DEVICE" == "emu" ]; then
	FB_UR=0
	ifconfig eth0 up
	udhcpc -i eth0
elif [ "$DEVICE" == "bpi" ]; then
	FB_UR=0
	echo 0 > "/sys/devices/platform/leds/leds/bpi:red:pwr/brightness"
else
	FB_UR=0
	echo 0 > /sys/class/leds/pmic_ledsb/brightness
fi
echo ${FB_UR} > /sys/class/graphics/fb0/rotate

if [ "$DEVICE" != "emu" ]; then
	env QT_QPA_PLATFORM=kobo:touchscreen_rotate=90:touchscreen_invert_x=auto:touchscreen_invert_y=auto:logicaldpitarget=0 chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh &
else
	env QT_QPA_PLATFORM=vnc:size=768x1024 chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh &
fi

if [ "$ROOTED" == "true" ]; then
	rc-service sshd start &
else
	echo "Not starting SSHd, device is not rooted."
fi
