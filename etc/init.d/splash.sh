#!/bin/sh

DISPLAY_DEBUG=$(cat /boot/flags/DISPLAY_DEBUG 2>/dev/null)
UPDATE_SPLASH=$(cat /opt/update/will_update 2>/dev/null)
DEVICE=$(cat /opt/inkbox_device)
if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n306" ] || [ "${DEVICE}" == "n249" ]; then
	FB_UR=3
elif [ "${DEVICE}" == "kt" ]; then
	FB_UR=1
elif [ "${DEVICE}" == "n873" ]; then
	FB_UR=0
else
	FB_UR=3
fi

echo ${FB_UR} > /sys/class/graphics/fb0/rotate

if [ "${DISPLAY_DEBUG}" != "true" ]; then
	if [ "${UPDATE_SPLASH}" == "true" ]; then
		killall -q update-splash
		/opt/bin/fbink/fbink -k -f -h -q
		/opt/bin/fbink/fbink -t regular=/etc/init.d/splash.d/fonts/resources/inter-b.ttf,size=20 "Updating" -m -M -h -q
		/opt/bin/update-splash &
	else
		echo "inkbox_splash" > /run/initrd-fifo
	fi
fi
