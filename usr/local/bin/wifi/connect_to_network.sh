#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)
[ -e "/run/connect_to_network.sh.pid" ] && EXISTING_PID=$(cat /run/connect_to_network.sh.pid) && if [ -d "/proc/${EXISTING_PID}" ]; then echo "Please terminate other instance(s) of \`connect_to_network.sh' before starting a new one. Process(es) ${EXISTING_PID} still running!" && exit 255; else rm /run/connect_to_network.sh.pid; fi
echo ${$} > "/run/connect_to_network.sh.pid"

quit() {
	rm -f "/run/connect_to_network.sh.pid"
	rm -f "/run/was_connected_to_wifi"
	exit ${1}
}

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."
	quit 1
else
	ESSID="${1}"
fi
if [ -z "${2}" ]; then
	echo "Warning: No PASSPHRASE argument, trying to connect to a open network"
	# To preserve compability with other programs, NONE should be gived anyway
	PASSPHRASE="NONE"
else
	PASSPHRASE="${2}"
fi

if [ "${DEVICE}" == "n873" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n306" ] ||  [ "${DEVICE}" == "n705" ] || [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n613" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="eth0"
elif [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "kt" ]; then
	WIFI_DEV="wlan0"
else
	WIFI_DEV="eth0"
fi

# To be sure
rm -f "/run/wpa_supplicant/eth0"

if [ "$PASSPHRASE" = "NONE" ]; then
    echo "Setting up wpa_supplicant.conf for no password"
	echo "network={" > /run/wpa_supplicant.conf
	echo "    ssid=\"${ESSID}\"" >> /run/wpa_supplicant.conf
    echo "    key_mgmt=NONE" >> /run/wpa_supplicant.conf
    echo "}" >> /run/wpa_supplicant.conf
else
	echo "Setting up wpa_supplicant.conf for password"
	wpa_passphrase "${ESSID}" "${PASSPHRASE}" > /run/wpa_supplicant.conf
fi
wpa_supplicant -D wext -i "${WIFI_DEV}" -c /run/wpa_supplicant.conf -O /run/wpa_supplicant -B
if [ ${?} != 0 ]; then
	echo "Failed to connect to network '${ESSID}'"
	cleanup
	quit 1
fi

if [ "${DEVICE}" == "n905b" ] || [ "${DEVICE}" == "n236" ] || [ "${DEVICE}" == "n437" ] || [ "${DEVICE}" == "n306" ] || [ "${DEVICE}" == "kt" ]; then
	timeout 120s udhcpc -i "${WIFI_DEV}"
else
	timeout 120s dhcpcd "${WIFI_DEV}"
fi

if [ ${?} != 0 ]; then
	echo "DHCP request failed."
	if [ -f "/run/stopping_wifi" ]; then
		echo "/run/stopping_wifi exists, dont shutting down wifi"
		rm "/run/stopping_wifi"
		exit 0
	else
		/usr/local/bin/wifi/toggle.sh off
	fi
	quit 1
fi

# Sync time
/usr/local/bin/timesync.sh
echo "Exiting"
rm /run/stopping_wifi
quit 0
