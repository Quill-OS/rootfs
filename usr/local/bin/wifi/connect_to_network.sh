#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)
[ -e "/run/connect_to_network.sh.pid" ] && EXISTING_PID=$(cat /run/connect_to_network.sh.pid) && echo "Please terminate other instance(s) of \`connect_to_network.sh' before starting a new one. Process(es) ${EXISTING_PID} still running!" && exit 255
echo ${$} > "/run/connect_to_network.sh.pid"

quit() {
	rm -f "/run/connect_to_network.sh.pid"
	exit ${1}
}

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."
	quit 1
else
	ESSID="${1}"
fi
if [ -z "${2}" ]; then
	echo "You must provide the 'passphrase' argument."
	quit 1
else
	PASSPHRASE="${2}"
fi

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

cleanup() {
	killall -q dhcpcd wpa_supplicant
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n437" ]; then
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
	if [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "n437" ]; then
		wlarm_le up
	fi
}

cleanup
setup

wpa_passphrase "${ESSID}" "${PASSPHRASE}" > /run/wpa_supplicant.conf
wpa_supplicant -D wext -i "${WIFI_DEV}" -c /run/wpa_supplicant.conf -O /run/wpa_supplicant -B
if [ ${?} != 0 ]; then
	echo "Failed to connect to network '${ESSID}'"
	cleanup
	quit 1
fi

if [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n306" ]; then
	udhcpc -i "${WIFI_DEV}"
else
	dhcpcd "${WIFI_DEV}"
fi

if [ ${?} != 0 ]; then
	echo "DHCP request failed."
	cleanup
	quit 1
fi

# Sync time
/usr/local/bin/timesync.sh
quit 0
