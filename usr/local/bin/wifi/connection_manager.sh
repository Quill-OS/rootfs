#!/bin/bash

DEVICE=$(cat /opt/inkbox_device)

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."
	exit 1
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

echo -n "Preparing WPA connection: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/prepare_network.sh "${ESSID}" "${PASSPHRASE}"

if [ ${?} != 0 ]; then
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
	echo "s - ERROR" >>  /run/wifi_stats
	exit 1
else
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
    echo "s - OK" >>  /run/wifi_stats
fi

echo -n "Getting DHCP: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/only_connect_to_network.sh

if [ ${?} != 0 ]; then
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
	echo "s - ERROR" >>  /run/wifi_stats
	exit 1
else
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
    echo "s - OK" >>  /run/wifi_stats
fi

echo -n "Syncing time: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/smarter_time_sync.sh

if [ ${?} != 0 ]; then
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
	echo "s - ERROR" >>  /run/wifi_stats
	exit 1
else
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
    echo "s - OK" >>  /run/wifi_stats
fi
