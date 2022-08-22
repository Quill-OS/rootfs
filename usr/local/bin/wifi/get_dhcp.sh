#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)
[ -e "/run/only_connect_to_network.sh.pid" ] && EXISTING_PID=$(cat /run/only_connect_to_network.sh.pid) && if [ -d "/proc/${EXISTING_PID}" ]; then echo "Please terminate other instance(s) of \`connect_to_network.sh' before starting a new one. Process(es) ${EXISTING_PID} still running!" && exit 255; else rm /run/only_connect_to_network.sh.pid; fi
echo ${$} > "/run/only_connect_to_network.sh.pid"

quit() {
	rm -f "/run/only_connect_to_network.sh.pid"
	exit ${1}
}

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi


if [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n306" ] || [ "${DEVICE}" == "kt" ]; then
	# Actually why not
	timeout 320s udhcpc -i "${WIFI_DEV}"
else
	timeout 320s dhcpcd "${WIFI_DEV}"
fi

if [ ${?} != 0 ]; then
	echo "Connecting failed."
	quit 1
fi

quit 0
