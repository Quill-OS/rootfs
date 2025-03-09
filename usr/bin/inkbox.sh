#!/bin/sh

FIRST_LAUNCH_SINCE_BOOT=$(cat /tmp/boot 2>/dev/null)
ROOTED=$(cat /opt/root/rooted)
DEVICE=$(cat /opt/inkbox_device)

if [ "${FIRST_LAUNCH_SINCE_BOOT}" == "true" ]; then
	echo "false" > /tmp/boot
	echo "true" > /kobo/tmp/first_launch_since_boot
else
	echo "false" > /kobo/tmp/first_launch_since_boot
fi

if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ]; then
	FB_UR=3
elif [ "${DEVICE}" == "n306" ]; then
	FB_UR=3
elif [ "${DEVICE}" == "n873" ]; then
	FB_UR=0
elif [ "${DEVICE}" == "emu" ]; then
	FB_UR=0
	ifconfig eth0 up
	udhcpc -i eth0
elif [ "${DEVICE}" == "bpi" ]; then
	FB_UR=0
elif [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n249" ]; then
	FB_UR=3
elif [ "${DEVICE}" == "n418" ] || [ "${DEVICE}" == "kt" ]; then
	FB_UR=1
else
	FB_UR=0
fi
echo ${FB_UR} > /sys/class/graphics/fb0/rotate

# Preventing KT libs from getting in the way (provided they were mounted for KOReader)
umount -l -f /kobo/lib

if [ "${DEVICE}" != "emu" ]; then
	env QT_QPA_PLATFORM="kobo:touchscreen_rotate=90:touchscreen_invert_x=auto:touchscreen_invert_y=auto:logicaldpitarget=0" chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh &
else
	env QT_QPA_PLATFORM="vnc:size=758x1024" chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh &
fi

if [ "${ROOTED}" == "true" ]; then
	rc-service sshd start &
else
	echo "Not starting SSHd, device is not rooted."
fi
