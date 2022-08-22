#!/bin/sh

DEVICE=$(cat /opt/inkbox_device)
[ -e "/run/prepare_network.sh.pid" ] && EXISTING_PID=$(cat "/run/prepare_network.sh.pid") && if [ -d "/proc/${EXISTING_PID}" ]; then echo "Please terminate other instance(s) of \`prepare_network.sh' before starting a new one. Process(es) ${EXISTING_PID} still running!" && exit 255; else rm -f "/run/prepare_network.sh.pid"; fi
echo ${$} > "/run/prepare_network.sh.pid"

quit() {
	rm -f "/run/prepare_network.sh.pid"
	exit ${1}
}

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."
	quit 1
else
	ESSID="${1}"
fi
if [ -z "${2}" ]; then
	echo "Warning: No 'PASSPHRASE' argument given, trying to connect to a open network"
	# To preserve compability with other programs, NONE should be given anyway
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

if [ "${PASSPHRASE}" = "NONE" ]; then
	echo "Setting up wpa_supplicant.conf for no password"
	echo "network={" > "/run/wpa_supplicant.conf"
	echo "    ssid=\"${ESSID}\"" >> "/run/wpa_supplicant.conf"
	echo "    key_mgmt=NONE" >> "/run/wpa_supplicant.conf"
	echo "}" >> "/run/wpa_supplicant.conf"
else
	echo "Setting up wpa_supplicant.conf for password"
	wpa_passphrase "${ESSID}" "${PASSPHRASE}" > /run/wpa_supplicant.conf
fi
wpa_supplicant -D wext -i "${WIFI_DEV}" -c /run/wpa_supplicant.conf -O /run/wpa_supplicant -B
if [ ${?} != 0 ]; then
	echo "Failed to prepare connection to network '${ESSID}'"
	quit 1
fi

if [ "${PASSPHRASE}" = "NONE" ]; then
	echo "No need to check password for Wi-Fi network"
	quit 0
else
	rm -f /run/correct_wifi_password
	timeout 120s /usr/local/bin/wifi/check_wifi_password.sh

	if test -f "/run/correct_wifi_password"; then
		echo "/run/correct_wifi_password exists."
		if grep -q true "/run/correct_wifi_password"; then
			echo "Password is correct"
			rm -f /run/correct_wifi_password
			quit 0
		else
			echo "Password is incorrect"
			rm -f /run/correct_wifi_password
			quit 1
		fi
	else
		echo "'/run/correct_wifi_password' doesn't exist. Checking for password propably timed out."
		quit 1
	fi
fi

quit 1
