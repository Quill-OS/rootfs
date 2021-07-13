#!/bin/sh

LOCKSCREEN=`cat /opt/config/12-lockscreen/config 2>/dev/null`
DEVICE=`cat /opt/inkbox_device`

rc-service wake_standby stop
> /tmp/power

while true; do
	inotifywait -e modify /tmp/power
	if grep -q "KEY_POWER" /tmp/power; then
		> /tmp/power
		break
	else
		> /tmp/power
		continue
	fi
done
sleep 1
chroot /kobo /usr/bin/fbgrab "/external_root/tmp/dump.png"
echo "true" > /tmp/sleep_mode

if [ "$LOCKSCREEN" == "true" ]; then
	killall inkbox-bin
	killall oobe-inkbox-bin
	killall lockscreen-bin
	killall calculator-bin
	killall scribble
	killall lightmaps
else
	kill -STOP `pidof inkbox-bin`
	kill -STOP `pidof oobe-inkbox-bin`
	kill -9 `pidof lockscreen-bin`
	kill -STOP `pidof calculator-bin`
	kill -STOP `pidof scribble`
	kill -STOP `pidof lightmaps`
fi

/opt/bin/fbink/fbink -k -f -q
/opt/bin/fbink/fbink -t regular=/etc/init.d/splash.d/fonts/resources/inter-b.ttf,size=20 "Sleeping" -m -M -q

sleep 1
if [ "$DEVICE" != "n613" ]; then
	CURRENT_BRIGHTNESS=`cat /kobo/var/run/brightness`
	echo "$CURRENT_BRIGHTNESS" > /tmp/savedBrightness
	/opt/bin/cinematic-brightness.sh 0 1
else
	CURRENT_BRIGHTNESS=`cat /opt/config/03-brightness/config`
	echo "$CURRENT_BRIGHTNESS" > /tmp/savedBrightness
	/opt/bin/cinematic-brightness.sh 0 1
fi

echo "false" > /kobo/inkbox/remount
> /tmp/power

sleep 1
rc-service wake_standby start
