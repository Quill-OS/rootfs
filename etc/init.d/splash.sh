#!/bin/sh

UPDATE_SPLASH=`cat /opt/update/will_update` 2>/dev/null
echo 0 > /sys/class/graphics/fb0/rotate

if [ "$UPDATE_SPLASH" == "true" ]; then
	killall -q update-splash
	/opt/bin/fbink/fbink -k -f -h -q
	/opt/bin/fbink/fbink -t regular=/etc/init.d/splash.d/fonts/resources/inter-b.ttf,size=20 "Updating" -m -M -h -q
	/opt/bin/update-splash &
else
	cd /etc/init.d/splash.d/bin; ./init_show &>/dev/null
fi
