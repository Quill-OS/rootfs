#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)
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
	rmmod "${WIFI_MODULE}"
	rmmod "${SDIO_WIFI_PWR_MODULE}"
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

if [ "${DEVICE}" != "n437" ]; then
	iwlist "${WIFI_DEV}" scanning | grep -o '".*"' | sed 's/"//g' | sed '/^[[:space:]]*$/d' > /run/wifi_networks_list
else
	wlarm_le escanresults | grep -w "SSID:" | cut -d '"' -f2 > /run/wifi_networks_list
fi
