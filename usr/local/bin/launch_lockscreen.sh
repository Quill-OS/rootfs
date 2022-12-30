#!/bin/sh

DEVICE="$(cat /opt/inkbox_device)"

if [ "${DEVICE}" != "emu" ]; then
	env QT_QPA_PLATFORM="kobo:touchscreen_rotate=90:touchscreen_invert_x=auto:touchscreen_invert_y=auto:logicaldpitarget=0" QT_FONT_DPI=${DPI} ADDSPATH="/mnt/onboard/.adds/" QTPATH="${ADDSPATH}/qt-linux-5.15.2-kobo" LD_LIBRARY_PATH="${QTPATH}lib:lib:" chroot /kobo /mnt/onboard/.adds/inkbox/lockscreen
else
	env QT_QPA_PLATFORM="vnc:size=758x1024" QT_FONT_DPI=${DPI} ADDSPATH="/mnt/onboard/.adds/" QTPATH="${ADDSPATH}/qt-linux-5.15.2-kobo" LD_LIBRARY_PATH="${QTPATH}lib:lib:" chroot /kobo /mnt/onboard/.adds/inkbox/lockscreen
fi
