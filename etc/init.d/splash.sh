#!/bin/sh

UPDATE_SPLASH=$(cat /opt/update/will_update 2>/dev/null)
DEVICE=$(cat /opt/inkbox_device)
if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ]; then
	FB_UR=3
elif [ "${DEVICE}" == "n873" ]; then
	FB_UR=0
else
	FB_UR=0
fi

echo ${FB_UR} > /sys/class/graphics/fb0/rotate

if [ "${UPDATE_SPLASH}" == "true" ]; then
	killall -q update-splash
	/opt/bin/fbink/fbink -k -f -h -q
	/opt/bin/fbink/fbink -t regular=/etc/init.d/splash.d/fonts/resources/inter-b.ttf,size=20 "Updating" -m -M -h -q
	/opt/bin/update-splash &
else
	cd /etc/init.d/splash.d/bin; ./init_show &>/dev/null
fi
