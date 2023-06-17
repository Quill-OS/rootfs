#!/bin/sh

DEVICE="$(cat /opt/inkbox_device)"
DARK_MODE="$(cat /data/config/10-dark_mode/config)"

if [ "${DEVICE}" != "emu" ]; then
	env QT_QPA_PLATFORM="kobo:touchscreen_rotate=90:touchscreen_invert_x=auto:touchscreen_invert_y=auto:logicaldpitarget=0" QT_FONT_DPI=${DPI} ADDSPATH="/mnt/onboard/.adds/" QTPATH="${ADDSPATH}/qt-linux-5.15.2-kobo/" LD_LIBRARY_PATH="${QTPATH}lib:/lib" chroot /kobo /mnt/onboard/.adds/inkbox/lockscreen
	# Displaying the screen as it was before the device went to sleep to avoid eInk issues
	sleep 0.1
	if [ "${DARK_MODE}" == "true" ]; then
		fbink -k -f -h
		fbink -g file="/tmp/lockscreen.png" -h
		fbink -s -f
	else
		fbink -k -f
		fbink -g file="/tmp/lockscreen.png"
		fbink -s -f
	fi
	rm -f "/tmp/lockscreen.png"
else
	env QT_QPA_PLATFORM="vnc:size=758x1024" QT_FONT_DPI=${DPI} ADDSPATH="/mnt/onboard/.adds/" QTPATH="${ADDSPATH}/qt-linux-5.15.2-kobo" LD_LIBRARY_PATH="${QTPATH}lib:/lib" chroot /kobo /mnt/onboard/.adds/inkbox/lockscreen
fi
