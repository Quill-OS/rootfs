#!/bin/sh

DARK_MODE=`cat /kobo/mnt/onboard/.adds/inkbox/.config/10-dark_mode/config`
LOCKSCREEN=`cat /kobo/mnt/onboard/.adds/inkbox/.config/12-lockscreen/config`
DEVICE=`cat /opt/inkbox_device`

rc-service sleep_standby stop
# Race condition
sleep 10
echo "1" > /sys/power/state-extended
echo "mem" > /sys/power/state
echo "false" > /tmp/sleep_mode

cinematic_brightness() {
	sleep 0.5
	SAVED_BRIGHTNESS=`cat /tmp/savedBrightness`
	/opt/bin/cinematic-brightness.sh "$SAVED_BRIGHTNESS" 0
}

if [ "$DARK_MODE" == "true" ]; then
	if [ "$LOCKSCREEN" == "true" ]; then
		chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh lockscreen
	else
		/opt/bin/fbink/fbink -k -f -h
		/opt/bin/fbink/fbink -g file=/tmp/dump.png -h
		kill -CONT `pidof inkbox-bin`
		kill -CONT `pidof oobe-inkbox-bin`
		kill -CONT `pidof calculator-bin`
		kill -CONT `pidof scribble`
		kill -CONT `pidof lightmaps`
		cinematic_brightness
	fi
else
        if [ "$LOCKSCREEN" == "true" ]; then
                chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh lockscreen
        else
		/opt/bin/fbink/fbink -k -f
		/opt/bin/fbink/fbink -g file=/tmp/dump.png
		kill -CONT `pidof inkbox-bin`
		kill -CONT `pidof oobe-inkbox-bin`
		kill -CONT `pidof calculator-bin`
		kill -CONT `pidof scribble`
		kill -CONT `pidof lightmaps`
		cinematic_brightness
	fi
fi

sleep 1
rc-service sleep_standby start
