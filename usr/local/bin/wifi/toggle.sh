DEVICE=$(cat /opt/inkbox_device)

if [ -z "${1}" ] || [ "${1}" != "off" ] || [ "${1}" != "on" ]; then
	echo "You must specify the 'mode' argument."
	echo "Available options: off, on"
	exit 1
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
}

if [ "${1}" == "off" ]; then
	cleanup
else
	setup
fi
