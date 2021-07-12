#!/bin/sh

/opt/bin/fbink/fbink -k -f -h

PORT=$(cat /tmp/app_vnc_port 2>/dev/null)
if [ -z "${PORT}" ]; then
	PORT=5900
fi

SERVER=$(cat /tmp/app_vnc_server 2>/dev/null)
PASSWORD=$(cat /tmp/app_vnc_password 2>/dev/null)

if [ ! -z "${PASSWORD}" ]; then
	LD_LIBRARY_PATH=/opt/qt5/lib QT_QPA_PLATFORM=kobo busybox chroot /opt/X11/vnc-touch /root/vnc/vnc "vnc://:${PASSWORD}@${SERVER}:${PORT}"
else
	LD_LIBRARY_PATH=/opt/qt5/lib QT_QPA_PLATFORM=kobo busybox chroot /opt/X11/vnc-touch /root/vnc/vnc "vnc://${SERVER}:${PORT}"
fi

rc-service inkbox_gui start
