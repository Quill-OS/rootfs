#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)

if [ -z "${1}" ]; then
	echo "You must specify the 'mode' argument."
	echo "Available options: off, on"
	exit 1
fi

if [ "${1}" == "off" ]; then
	echo "Turning Wi-Fi OFF"
elif [ "${1}" == "on" ]; then
	echo "Turning Wi-Fi ON"
else
	echo "Invalid 'mode' argument."
	echo "Available options: off, on"
	exit 1
fi

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "236" ] || [ "${DEVICE}" == "n306" ]; then
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
elif [ "${DEVICE}" == "kt" ]; then
	WIFI_MODULE="ar6003"
	WIFI_DEV="wlan0"
else
	WIFI_MODULE="/modules/dhd.ko"
	SDIO_WIFI_PWR_MODULE="/modules/sdio_wifi_pwr.ko"
	WIFI_DEV="eth0"
fi

cleanup() {
	# To be sure...
	/usr/local/bin/wifi/prepare_changing_wifi.sh
	killall -q dhcpcd wpa_supplicant udhcpc
	killall -q dhcpcd wpa_supplicant udhcpc
	sleep 0.5
	killall -9 dhcpcd wpa_supplicant udhcpc	
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n437" ]; then
		wlarm_le down
	fi
	ifconfig "${WIFI_DEV}" down

	if [ "${DEVICE}" != "kt" ]; then
		rmmod "${WIFI_MODULE}"
		rmmod "${SDIO_WIFI_PWR_MODULE}"
	else
		modprobe -r "${WIFI_MODULE}"
	fi
}

setup() {
	if [ "${DEVICE}" != "kt" ]; then
		insmod "${SDIO_WIFI_PWR_MODULE}"
		insmod "${WIFI_MODULE}"
	else
		modprobe "${WIFI_MODULE}"
	fi
	# Race condition
	sleep 1.5
	ifconfig "${WIFI_DEV}" up
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n437" ]; then
		wlarm_le up
	fi
}

if [ "${1}" == "off" ]; then
	cleanup
else
	setup
fi
