#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."
	exit 1
else
	ESSID="${1}"
fi
if [ -z "${2}" ]; then
	echo "You must provide the 'passphrase' argument."
	exit 1
else
	PASSPHRASE="${2}"
fi

if [ "${DEVICE}" == "n873" ]; then
	WIFI_MODULE="/modules/wifi/8189fs.ko"
	SDIO_WIFI_PWR_MODULE="/modules/drivers/mmc/card/sdio_wifi_pwr.ko"
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ]; then
	WIFI_MODULE="/modules/dhd.ko"
	SDIO_WIFI_PWR_MODULE="/modules/sdio_wifi_pwr.ko"
	WIFI_DEV="eth0"
else
	WIFI_MODULE="/modules/dhd.ko"
	SDIO_WIFI_PWR_MODULE="/modules/sdio_wifi_pwr.ko"
	WIFI_DEV="eth0"
fi

cleanup() {
	killall -q dhcpcd wpa_supplicant
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ]; then
		wlarm_le down
	fi
	ifconfig "${WIFI_DEV}" down
	rmmod "${WIFI_MODULE}" 2> /dev/null
	rmmod "${SDIO_WIFI_PWR_MODULE}" 2> /dev/null
}

setup() {
	insmod "${SDIO_WIFI_PWR_MODULE}"
	insmod "${WIFI_MODULE}"
	# Race condition
	sleep 1.5
	ifconfig "${WIFI_DEV}" up
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ]; then
		wlarm_le up
	fi
}

cleanup
setup

wpa_passphrase "${ESSID}" "${PASSPHRASE}" > /run/wpa_supplicant.conf
wpa_supplicant -D wext -i eth0 -c /run/wpa_supplicant.conf -O /run/wpa_supplicant -B
if [ "${DEVICE}" == "n905b" ]; then
	busybox udhcpc
else
	dhcpcd eth0
fi

if [ ${?} != 0 ]; then
	echo "DHCP request failed."
	cleanup
	exit 1
fi
