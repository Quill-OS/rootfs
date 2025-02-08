#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)
[ -e "/run/get_dhcp.sh.pid" ] && EXISTING_PID=$(cat "/run/get_dhcp.sh.pid") && if [ -d "/proc/${EXISTING_PID}" ]; then echo "Please terminate other instance(s) of \`get_dhcp.sh' before starting a new one. Process(es) ${EXISTING_PID} still running!" && exit 255; else rm -f "/run/get_dhcp.sh.pid"; fi
echo ${$} > "/run/get_dhcp.sh.pid"

quit() {
	rm -f "/run/get_dhcp.sh.pid"
	exit ${1}
}

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n249" ] || [ "${DEVICE}" == "n418" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi


if [ "${DEVICE}" != "n873" ]; then
	timeout 320s udhcpc -i "${WIFI_DEV}"
else
	timeout 320s dhcpcd "${WIFI_DEV}"
fi

if [ ${?} != 0 ]; then
	echo "DHCP lease acquisition failed."
	quit 1
fi

quit 0
