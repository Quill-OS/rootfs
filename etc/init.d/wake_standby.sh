#!/bin/bash

DARK_MODE=$(cat /kobo/mnt/onboard/.adds/inkbox/.config/10-dark_mode/config)
LOCKSCREEN=$(cat /kobo/mnt/onboard/.adds/inkbox/.config/12-lockscreen/config)
DEVICE=$(cat /opt/inkbox_device)

rc-service sleep_standby stop

# Race condition; going to sleep
echo "false" > /tmp/sleep_standby
sleep 10
echo "1" > /sys/power/state-extended
sleep 2
echo "mem" > /sys/power/state

# Waking up
echo "false" > /tmp/sleep_mode

cinematic_brightness() {
	sleep 0.5
	SAVED_BRIGHTNESS=$(cat /tmp/savedBrightness)
	/opt/bin/cinematic-brightness.sh "${SAVED_BRIGHTNESS}" 0
}

power_button_watchdog() {
	> /tmp/power
	while true; do
		if ! grep -q "true" /tmp/sleep_standby; then
			inotifywait -e modify /tmp/power
		        if grep -q "KEY_POWER" /tmp/power || grep -q "KEY_F1" /tmp/power; then
				> /tmp/power
				echo "true" > /tmp/wake_watchdog_termination
				kill -9 $(cat /run/connect_to_network.sh.pid 2>/dev/null)
				rm -f /run/connect_to_network.sh.pid
				rm -f /run/was_connected_to_wifi
				echo "true" > /tmp/sleep_now
				break
			else
				> /tmp/power
				continue
			fi
		else
			break
		fi
	done
}

if [ "${DARK_MODE}" == "true" ]; then
	if [ "${LOCKSCREEN}" == "true" ]; then
		chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh lockscreen
	else
		/opt/bin/fbink/fbink -k -f -h
		/opt/bin/fbink/fbink -g file=/tmp/dump.png -h
		kill -CONT $(pidof inkbox-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof oobe-inkbox-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof calculator-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof scribble 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof lightmaps 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof qreversi-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof 2048-bin 2>/dev/null) 2>/dev/null
		cinematic_brightness
	fi
else
        if [ "${LOCKSCREEN}" == "true" ]; then
                chroot /kobo /mnt/onboard/.adds/inkbox/inkbox.sh lockscreen
        else
		/opt/bin/fbink/fbink -k -f
		/opt/bin/fbink/fbink -g file=/tmp/dump.png
		kill -CONT $(pidof inkbox-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof oobe-inkbox-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof calculator-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof scribble 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof lightmaps 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof qreversi-bin 2>/dev/null) 2>/dev/null
		kill -CONT $(pidof 2048-bin 2>/dev/null) 2>/dev/null
		cinematic_brightness
	fi
fi

if grep -q "true" /run/was_connected_to_wifi 2>/dev/null; then
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

	insmod "${SDIO_WIFI_PWR_MODULE}"
	insmod "${WIFI_MODULE}"
	# Race condition
	sleep 1.5
	ifconfig "${WIFI_DEV}" up
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n437" ]; then
		wlarm_le up
	fi
	ESSID=$(cat /data/config/17-wifi_connection_information/essid 2>/dev/null)
	PASSPHRASE=$(cat /data/config/17-wifi_connection_information/passphrase 2>/dev/null)
	if [ ! -z "${ESSID}" ] && [ ! -z "${PASSPHRASE}" ]; then
		power_button_watchdog &
		POWER_BUTTON_WATCHDOG_PID=${!}
		disown
		/usr/local/bin/wifi/connect_to_network.sh "${ESSID}" "${PASSPHRASE}"
		if ! grep -q "true" /tmp/wake_watchdog_termination 2>/dev/null; then
			kill -9 ${POWER_BUTTON_WATCHDOG_PID}
		fi
		rm -f /tmp/wake_watchdog_termination
		rm -f /run/was_connected_to_wifi
	else
		rm -f /run/was_connected_to_wifi
	fi
fi

sleep 1
rc-service sleep_standby start
