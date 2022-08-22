#!/bin/sh

rm -f /run/wifi_stats
touch /run/wifi_stats

rm -f /run/wifi_logs
touch /run/wifi_logs

rm -f /run/stopping_wifi

DEVICE=$(cat /opt/inkbox_device)

if [ -z "${1}" ]; then
	echo "You must provide the 'ESSID' argument."  >> /run/wifi_logs 2>&1
	exit 1
else
	ESSID="${1}"
fi
if [ -z "${2}" ]; then
	echo "Warning: No PASSPHRASE argument, trying to connect to a open network"  >> /run/wifi_logs 2>&1
	# To preserve compability with other programs, NONE should be gived anyway
	PASSPHRASE="NONE"
else
	PASSPHRASE="${2}"
fi

echo -n "Preparing WPA connection: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/prepare_network.sh "${ESSID}" "${PASSPHRASE}" >> /run/wifi_logs 2>&1

if [ ${?} != 0 ]; then
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
	echo "s - ERROR" >>  /run/wifi_stats
	sleep 3
	if [ -f "/run/stopping_wifi" ]; then
		echo "/run/stopping_wifi exists, dont shutting down wifi"
		rm /run/stopping_wifi
		exit 0
	else
		echo "Turning wifi off from connection_manager"
		/usr/local/bin/wifi/toggle.sh off
	fi
	exit 1
else
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
    echo "s - OK" >>  /run/wifi_stats
fi

echo -n "Getting DHCP: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/get_dhcp.sh >> /run/wifi_logs 2>&1

if [ ${?} != 0 ]; then
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
	echo "s - ERROR" >>  /run/wifi_stats
	sleep 3
	if [ -f "/run/stopping_wifi" ]; then
		echo "/run/stopping_wifi exists, dont shutting down wifi"
		rm /run/stopping_wifi
		exit 0
	else
		echo "Turning wifi off from connection_manager"
		/usr/local/bin/wifi/toggle.sh off
	fi
	exit 1
else
	# remove the newline, also its here to not change the exit code
	truncate -s -1 /run/wifi_stats
    echo "s - OK" >>  /run/wifi_stats
fi

# Here its connected, so say yes to it
echo "true" > /run/was_connected_to_wifi

echo -n "Syncing time: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q /usr/local/bin/wifi/smarter_time_sync.sh >> /run/wifi_logs 2>&1

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

echo -n "Checking internet connection: " >>  /run/wifi_stats
/usr/bin/time -f '%e' -a -o /run/wifi_stats -q ping -4 -c 3 1.1.1.1 >> /run/wifi_logs 2>&1

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

rm /run/stopping_wifi
