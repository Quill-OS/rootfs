#!/bin/sh

rm -f "/run/wifi_stats"
touch "/run/wifi_stats"

rm -f "/var/log/wifi.log"
touch "/var/log/wifi.log"

rm -f "/run/stopping_wifi"

DEVICE=$(cat /opt/inkbox_device)

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."  >> "/var/log/wifi.log" 2>&1
	exit 1
else
	ESSID="${1}"
fi
if [ -z "${2}" ]; then
	echo "Warning: No 'PASSPHRASE' argument provided, trying to connect to a open network"  >> "/var/log/wifi.log" 2>&1
	# To preserve compability with other programs, NONE should be given anyway
	PASSPHRASE="NONE"
else
	PASSPHRASE="${2}"
fi

echo -n "Preparing WPA connection: " >> "/run/wifi_stats"
# Because dhd.ko is the worst Wi-Fi driver I have ever encountered in my whole life
if [ "${DEVICE}" == "n905c" ] || [ "${DEVICE}" == "n437" ]; then
	MAGIC_WORD="No, thanks" /usr/local/bin/wifi/toggle.sh off
	/usr/local/bin/wifi/toggle.sh on
fi
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/prepare_network.sh "${ESSID}" "${PASSPHRASE}" >> "/var/log/wifi.log" 2>&1

if [ ${?} != 0 ]; then
	# Remove the newline, also it's here to prevent changing the exit code
	truncate -s -1 "/run/wifi_stats"
	echo "s - ERROR" >> "/run/wifi_stats"
	sleep 3
	if [ -f "/run/stopping_wifi" ]; then
		echo "'/run/stopping_wifi' exists, not shutting down Wi-Fi"
		rm /run/stopping_wifi
		exit 0
	else
		echo "Turning Wi-Fi OFF from connection_manager"
		/usr/local/bin/wifi/toggle.sh off
	fi
	exit 1
else
	# Same thing here
	truncate -s -1 "/run/wifi_stats"
	echo "s - OK" >> "/run/wifi_stats"
fi

echo -n "Getting DHCP: " >> "/run/wifi_stats"
/usr/bin/time -f '%e' -a -o "/run/wifi_stats" -q /usr/local/bin/wifi/get_dhcp.sh >> "/var/log/wifi.log" 2>&1

if [ ${?} != 0 ]; then
	truncate -s -1 "/run/wifi_stats"
	echo "s - ERROR" >> "/run/wifi_stats"
	sleep 3
	if [ -f "/run/stopping_wifi" ]; then
		echo "'/run/stopping_wifi' exists, not shutting down Wi-Fi"
		rm "/run/stopping_wifi"
		exit 0
	else
		echo "Turning Wi-Fi OFF from connection_manager" >> "/var/log/wifi.log" 2>&1
		/usr/local/bin/wifi/toggle.sh off
	fi
	exit 1
else
	truncate -s -1 "/run/wifi_stats"
	echo "s - OK" >> "/run/wifi_stats"
fi

# Here, it's connected; say yes to it
echo "true" > "/run/was_connected_to_wifi"

echo -n "Syncing time: " >> "/run/wifi_stats"
/usr/bin/time -f '%e' -a -o "/run/wifi_stats" -q /usr/local/bin/timesync.sh >> "/var/log/wifi.log" 2>&1

if [ ${?} != 0 ]; then
	truncate -s -1 "/run/wifi_stats"
	echo "s - ERROR" >> "/run/wifi_stats"
	exit 1
else
	truncate -s -1 "/run/wifi_stats"
	echo "s - OK" >> "/run/wifi_stats"
fi

echo -n "Checking internet connection: " >> "/run/wifi_stats"
/usr/bin/time -f '%e' -a -o "/run/wifi_stats" -q ping -4 -c 3 1.1.1.1 >> "/var/log/wifi.log" 2>&1

if [ ${?} != 0 ]; then
	truncate -s -1 "/run/wifi_stats"
	echo "s - ERROR" >> "/run/wifi_stats"
	exit 1
else
	truncate -s -1 "/run/wifi_stats"
	echo "s - OK" >> "/run/wifi_stats"
fi

rm "/run/stopping_wifi"
