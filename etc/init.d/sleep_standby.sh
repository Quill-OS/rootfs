#!/bin/bash

LOCKSCREEN=$(cat /opt/config/12-lockscreen/config 2>/dev/null)
DEVICE=$(cat /opt/inkbox_device)

echo "true" > /tmp/sleep_standby
rc-service wake_standby stop
> /tmp/power

while true; do
	if grep -q "true" /tmp/sleep_now 2>/dev/null; then
		rm -f /tmp/sleep_now
		break
	fi

	inotifywait -e modify /tmp/power
	if grep -q "KEY_POWER" /tmp/power || grep -q "KEY_F1" /tmp/power; then
		> /tmp/power
		break
	else
		> /tmp/power
		continue
	fi
done

echo "true" > /tmp/sleep_mode
sleep 1
chroot /kobo /usr/bin/fbgrab "/external_root/tmp/dump.png"

if [ "${LOCKSCREEN}" == "true" ]; then
	killall -q inkbox-bin
	killall -q oobe-inkbox-bin
	killall -q lockscreen-bin
	killall -q calculator-bin
	killall -q scribble
	killall -q lightmaps
else
	kill -STOP $(pidof inkbox-bin 2>/dev/null) 2>/dev/null
	kill -STOP $(pidof oobe-inkbox-bin 2>/dev/null) 2>/dev/null
	kill -9 $(pidof lockscreen-bin 2>/dev/null) 2>/dev/null
	kill -STOP $(pidof calculator-bin 2>/dev/null) 2>/dev/null
	kill -STOP $(pidof scribble 2>/dev/null) 2>/dev/null
	kill -STOP $(pidof lightmaps 2>/dev/null) 2>/dev/null
fi

/opt/bin/fbink/fbink -k -f -q
/opt/bin/fbink/fbink -t regular=/etc/init.d/splash.d/fonts/resources/inter-b.ttf,size=20 "Sleeping" -m -M -q

sleep 1
if [ "${DEVICE}" != "n613" ]; then
	CURRENT_BRIGHTNESS=$(cat /kobo/var/run/brightness)
	echo "${CURRENT_BRIGHTNESS}" > /tmp/savedBrightness
	/opt/bin/cinematic-brightness.sh 0 1
else
	CURRENT_BRIGHTNESS=$(cat /opt/config/03-brightness/config)
	echo "${CURRENT_BRIGHTNESS}" > /tmp/savedBrightness
	/opt/bin/cinematic-brightness.sh 0 1
fi

if [ -d "/sys/class/net/${WIFI_DEV}" ]; then
	if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ]; then
		WIFI_MODULE="/modules/wifi/8189fs.ko"
		SDIO_WIFI_PWR_MODULE="/modules/drivers/mmc/card/sdio_wifi_pwr.ko"
		WIFI_DEV="eth0"
	elif [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ]; then
		WIFI_MODULE="/modules/dhd.ko"
		SDIO_WIFI_PWR_MODULE="/modules/sdio_wifi_pwr.ko"
		WIFI_DEV="eth0"
	elif [ "${DEVICE}" == "n437" ]; then
		WIFI_MODULE="/modules/wifi/bcmdhd.ko"
		SDIO_WIFI_PWR_MODULE="/modules/drivers/mmc/card/sdio_wifi_pwr.ko"
		WIFI_DEV="wlan0"
	else
		WIFI_MODULE="/modules/dhd.ko"
		SDIO_WIFI_PWR_MODULE="/modules/sdio_wifi_pwr.ko"
		WIFI_DEV="eth0"
	fi

	# Checking if we have a fully configured Wi-Fi interface
	if grep -q "up" "/sys/class/net/${WIFI_DEV}/operstate"; then
		echo "true" > /run/was_connected_to_wifi
	fi

	killall -q dhcpcd wpa_supplicant
	ifconfig "${WIFI_DEV}" down 2>/dev/null
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n437" ]; then
		wlarm_le down
	fi
	rmmod "${WIFI_MODULE}" 2> /dev/null
	rmmod "${SDIO_WIFI_PWR_MODULE}" 2> /dev/null
fi

echo "false" > /kobo/inkbox/remount
> /tmp/power

sleep 1
rc-service wake_standby start
